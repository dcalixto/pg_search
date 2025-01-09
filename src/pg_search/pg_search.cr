module PgSearch
  macro included
    macro pg_search_scope(name, options)
      def self.\{{name.id}}(query : String)
        return [] of self if query.blank?
        
        tsearch = PgSearch::Features::TSearch.new(
          dictionary: \{{options[:using][:tsearch][:dictionary]}},
          prefix: \{{options[:using][:tsearch][:prefix]}}
        )
        
        trigram = PgSearch::Features::Trigram.new(
          threshold: \{{options[:using][:trigram][:threshold]}}
        )
        
        columns = \{{options[:against]}}
        
        sql = <<-SQL
          SELECT *, 
            #{tsearch.rank("#{columns.join(" || ' ' || ")}", query)} * 2.0 +
            #{trigram.rank(query, "#{columns.join(" || ' ' || ")}")} * 0.5 as rank
          FROM #{table_name}
          WHERE 
            #{tsearch.conditions(query, columns.join(" || ' ' || "))} OR
            #{trigram.conditions(query, columns.join(" || ' ' || "))}
          ORDER BY rank DESC, created_at DESC
        SQL
        
        DB.connect(DB_URL) do |db|
          db.query_all(sql, as: self)
        end
      end
    end
  end
end
