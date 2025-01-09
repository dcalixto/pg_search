module PgSearch
  module Features
    class Trigram
      property threshold : Float64 = 0.3
      property word_similarity : Bool = false

      def initialize(@threshold = 0.3, @word_similarity = false)
      end

      def conditions(query : String, document : String)
        if threshold > 0
          "#{similarity_function}(#{normalized_query(query)}, #{normalized_document(document)}) > #{threshold}"
        else
          "#{normalized_query(query)} #{infix_operator} #{normalized_document(document)}"
        end
      end

      def rank(query : String, document : String)
        "#{similarity_function}(#{normalized_query(query)}, #{normalized_document(document)})"
      end

      private def similarity_function
        word_similarity ? "word_similarity" : "similarity"
      end

      private def infix_operator
        word_similarity ? "<%" : "%"
      end

      private def normalized_query(query : String)
        PG::EscapeHelper.escape_literal(query)
      end

      private def normalized_document(document : String)
        document
      end
    end
  end
end
