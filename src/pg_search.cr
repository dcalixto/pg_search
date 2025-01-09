require "./pg_search/*"
require "./pg_search/features/*"

module PgSearch
  DB_URL = ENV["DATABASE_URL"]? || "postgres://postgres:postgres@localhost:5432/pg_search_test"
  
  extend self

  macro included
    def self.query(sql)
      DB.connect(DB_URL) do |db|
        db.exec(sql)
      end
    end

    def self.query_all(sql)
      DB.connect(DB_URL) do |db|
        db.query_all(sql, as: self)
      end
    end

    def self.calculate_engagement_score(id : Int64) : Float64
      PgSearch.calculate_engagement_score(id)
    end
  end

  macro searchable_columns(columns, options = nil)
    def self.search(query : String, config = {} of Symbol => String|Bool|Float64)
      return [] of self if query.blank?
      
      tsearch = TSearch.new(
        dictionary: config[:dictionary]? || "english",
        prefix: config[:prefix]? || false,
        any_word: config[:any_word]? || false
      )
      
      sanitized_query = PG::EscapeHelper.escape_literal("%#{query}%")
      where_conditions = {{ columns }}.map { |col| "#{table_name}.#{col} ILIKE #{sanitized_query}" }
      
      sql = <<-SQL
        SELECT DISTINCT #{table_name}.*,
          COALESCE(pes.engagement, 0) as engagement_score,
          ts_rank(
            setweight(#{tsearch.search_vector("title")}, 'A') ||
            setweight(#{tsearch.search_vector("body")}, 'B') ||
            setweight(to_tsvector('#{tsearch.dictionary}', COALESCE(string_agg(comments.body, ' '), '')), 'C'),
            to_tsquery('#{tsearch.dictionary}', '#{tsearch.search_query(query)}')
          ) * (1 + COALESCE(pes.engagement, 0)) as rank
        FROM #{table_name}
        LEFT JOIN post_engagement_scores pes ON pes.id = #{table_name}.id
        LEFT JOIN comments ON comments.commentable_id = #{table_name}.id
          AND comments.commentable_type = '#{self}'
        WHERE #{where_conditions.join(" OR ")}
        GROUP BY #{table_name}.id, pes.engagement
        ORDER BY rank DESC, #{table_name}.created_at DESC
      SQL

      DB.connect(DB_URL) do |db|
        db.query_all(sql, as: self)
      end
    end

    def self.advanced_search(query : String, options = {} of Symbol => String|Bool)
      return [] of self if query.blank?
      
      sanitized_query = PG::EscapeHelper.escape_literal("%#{query}%")
      sql = <<-SQL
        WITH search_results AS (
          SELECT
            p.*,
            COALESCE(pes.engagement, 0) as engagement_score,
            ts_rank(
              setweight(to_tsvector('english', p.title), 'A') ||
              setweight(to_tsvector('english', p.body), 'B') ||
              setweight(to_tsvector('english', COALESCE(string_agg(c.body, ' '), '')), 'C'),
              plainto_tsquery('english', #{sanitized_query})
            ) as text_rank
          FROM posts p
          LEFT JOIN post_engagement_scores pes ON p.id = pes.id
          LEFT JOIN comments c ON c.commentable_id = p.id AND c.commentable_type = 'Post'
          WHERE
            p.title ILIKE #{sanitized_query} OR
            p.body ILIKE #{sanitized_query} OR
            c.body ILIKE #{sanitized_query}
          GROUP BY p.id, pes.engagement
        )
        SELECT *,
          (text_rank * (1 + engagement_score)) as final_rank
        FROM search_results
        ORDER BY final_rank DESC, created_at DESC
      SQL

      DB.connect(DB_URL) do |db|
        db.query_all(sql, as: self)
      end
    end
  end

  macro pg_search_scope(name, options)
    def self.{{name.id}}(query : String)
      return [] of self if query.blank?
      
      tsearch = Features::TSearch.new
      tsearch.dictionary = {{options[:using][:tsearch][:dictionary]}}
      tsearch.prefix = {{options[:using][:tsearch][:prefix]}}
      
      sql = <<-SQL
        SELECT *,
          #{tsearch.rank("to_tsvector('#{tsearch.dictionary}', #{table_name}.{{options[:against]}})", query)} as rank
        FROM #{table_name}
        WHERE #{tsearch.search_vector("#{table_name}.{{options[:against]}}")} @@ to_tsquery('#{tsearch.dictionary}', #{tsearch.search_query(query)})
        ORDER BY rank DESC, created_at DESC
      SQL
      
      DB.connect(DB_URL) do |db|
        db.query_all(sql, as: self)
      end
    end
  end

  def self.start_auto_refresh(interval_seconds = 300)
    spawn do
      loop do
        refresh_engagement_scores
        sleep interval_seconds
      end
    end
  end

  def self.calculate_engagement_score(id : Int64) : Float64
    DB.connect(DB_URL) do |db|
      result = db.query_one? <<-SQL, id, as: {Float64}
        SELECT COALESCE(
          SUM(
            CASE
              WHEN positive IS TRUE THEN 1
              WHEN negative IS TRUE THEN -1
              ELSE value
            END
          )::float,
          0.0
        ) as engagement
        FROM votes
        WHERE resource_id = $1
      SQL
      result || 0.0
    end
  end

  def self.refresh_engagement_scores
    DB.connect(DB_URL) do |db|
      db.exec "REFRESH MATERIALIZED VIEW post_engagement_scores"
    end
  end
end