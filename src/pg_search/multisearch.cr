module PgSearch
  module Multisearch
    extend self

    def rebuild(model : Class, clean_up : Bool = true, transactional : Bool = true)
      if transactional
        DB.transaction do
          execute(model, clean_up)
        end
      else
        execute(model, clean_up)
      end
    end

    private def execute(model, clean_up)
      if clean_up
        Document.delete_by_type(model.name)
      end

      Rebuilder.new(model).rebuild
    end

    class Document
      include DB::Serializable
      include PgSearch

      property id : Int64?
      property content : String
      property searchable_type : String
      property searchable_id : Int64
      property created_at : Time
      property updated_at : Time?

      def self.delete_by_type(type : String)
        DB.connect(DB_URL) do |db|
          db.exec "DELETE FROM pg_search_documents WHERE searchable_type = $1", type
        end
      end

      def self.search(query : String)
        tsearch = Features::TSearch.new
        sql = <<-SQL
          SELECT * FROM pg_search_documents
          WHERE #{tsearch.conditions(query, "content")}
          ORDER BY #{tsearch.rank("content", query)} DESC
        SQL

        DB.connect(DB_URL) do |db|
          db.query_all(sql, as: self)
        end
      end
    end

    class NotMultisearchable < Exception
      def initialize(model_class)
        super("#{model_class.name} is not multisearchable")
      end
    end
  end
end
