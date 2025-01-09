module PgSearch
  module Features
    class DMetaphone
      def initialize(query : String, options = {} of Symbol => String | Bool)
        @options = options.merge({dictionary: "simple"})
        @tsearch = TSearch.new
      end

      def conditions(query : String, document : String)
        "pg_search_dmetaphone(#{document}) @@ pg_search_dmetaphone(#{query})"
      end

      def rank(query : String, document : String)
        "ts_rank(pg_search_dmetaphone(#{document}), pg_search_dmetaphone(#{query}))"
      end
    end
  end
end
