module PgSearch
  macro searchable_columns(columns)
    @@searchable_columns = {{columns}}
    
    def self.searchable_columns
      @@searchable_columns
    end
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

    def self.table_name
      "pg_search_documents"
    end

    searchable_columns ["content"]

    def self.create_for(record, content)
      document = new(
        content: content,
        searchable_type: record.class.name,
        searchable_id: record.id.not_nil!,
        created_at: Time.utc,
        updated_at: Time.utc
      )
      document.save
    end

    def self.multisearch(query : String)
      search(query)
    end
  end
end
