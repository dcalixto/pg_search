module PgSearch
  module Features
    class Trigram
      property threshold : Float64 = 0.3

      def initialize(@threshold : Float64 = 0.3)
      end

      def conditions(query, columns)
        "similarity(#{columns}, #{PG::EscapeHelper.escape_literal(query)}) > #{@threshold}"
      end

      def rank(query, columns)
        "similarity(#{columns}, #{PG::EscapeHelper.escape_literal(query)})"
      end
    end
  end
end
