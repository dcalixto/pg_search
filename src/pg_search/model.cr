module PgSearch
  module Model
    macro included
      extend ClassMethods
    end

    module ClassMethods
      macro pg_search_scope(name, options)
        def self.{{name.id}}(*args)
          config = SearchConfig.new({{options}})
          
          sql = String.build do |str|
            str << "SELECT *, "
            str << config.rank_expression
            str << " FROM #{table_name} "
            str << "WHERE #{config.conditions} "
            str << "ORDER BY #{config.order_by}"
          end
          
          query_all(sql, as: self)
        end
      end

      macro multisearchable(options = nil)
        after_save :update_pg_search_document
        
        private def update_pg_search_document
          content = [{{options[:against]}}].flatten.compact.join(" ")
          PgSearch::Document.create_for(self, content)
        end
      end
    end
  end
end
