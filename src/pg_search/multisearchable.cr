module PgSearch
  module Multisearchable
    macro included
      property pg_search_document : PgSearch::Multisearch::Document?
      
      after_save :update_pg_search_document
      
      def searchable_text
        columns = pg_search_options[:against].as(Array)
        columns.map { |column| self.responds_to?(column) ? self.send(column) : "" }.join(" ")
      end
      
      def update_pg_search_document
        return unless should_have_document?
        
        attrs = {
          content: searchable_text,
          searchable_type: self.class.name,
          searchable_id: id.not_nil!,
          created_at: Time.utc,
          updated_at: Time.utc
        }
        
        if pg_search_document
          pg_search_document.not_nil!.update(attrs)
        else
          @pg_search_document = PgSearch::Multisearch::Document.create(attrs)
        end
      end
      
      private def should_have_document?
        return false unless id
        
        if_conditions = pg_search_options[:if]?.try(&.as(Array)) || [] of Symbol
        unless_conditions = pg_search_options[:unless]?.try(&.as(Array)) || [] of Symbol
        
        if_conditions.all? { |condition| send(condition) } &&
        unless_conditions.all? { |condition| !send(condition) }
      end
    end

    macro class_attribute(name)
      @@{{name.id}} = nil
      
      def self.{{name.id}}
        @@{{name.id}}
      end
      
      def self.{{name.id}}=(value)
        @@{{name.id}} = value
      end
      
      def {{name.id}}
        @@{{name.id}}
      end
      
      def {{name.id}}=(value)
        @@{{name.id}} = value
      end
    end
  end
end
