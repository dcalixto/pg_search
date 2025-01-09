module PgSearch
  module Multisearch
    class Rebuilder
      def initialize(@model : Class, @time_source : -> Time = ->{ Time.utc })
      end

      def rebuild
        if conditional? || dynamic?
          rebuild_conditionally
        else
          DB.connect(DB_URL) do |db|
            db.exec rebuild_sql
          end
        end
      end

      private def rebuild_sql
        <<-SQL
          INSERT INTO pg_search_documents 
          (searchable_type, searchable_id, content, created_at, updated_at)
          SELECT 
            '#{@model.name}' AS searchable_type,
            #{@model.table_name}.id AS searchable_id,
            (#{content_expressions}) AS content,
            '#{@time_source.call}' AS created_at,
            '#{@time_source.call}' AS updated_at
          FROM #{@model.table_name}
        SQL
      end

      private def content_expressions
        columns.map do |column|
          "COALESCE(#{@model.table_name}.#{column}::text, '')"
        end.join(" || ' ' || ")
      end

      private def rebuild_conditionally
        @model.all.each do |record|
          record.update_pg_search_document
        end
      end

      private def columns
        @model.pg_search_options[:against].as(Array)
      end

      private def conditional?
        @model.pg_search_options[:if]? || @model.pg_search_options[:unless]?
      end

      private def dynamic?
        columns.any? { |column| !@model.column_names.includes?(column.to_s) }
      end
    end
  end
end
