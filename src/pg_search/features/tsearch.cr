module PgSearch
  module Features
    class TSearch
      DISALLOWED_TSQUERY_CHARACTERS = /['?\\:''ʻʼ]/

      property dictionary : String = "english"
      property prefix : Bool = false
      property negation : Bool = false
      property any_word : Bool = false
      property normalization : Int32 = 0
      property highlight_options : Hash(String, String | Bool | Int32) = {} of String => String | Bool | Int32

      def search_vector(text : String, weight : String? = nil)
        vector = "to_tsvector('#{dictionary}', #{text})"
        weight ? "setweight(#{vector}, '#{weight}')" : vector
      end

      def search_query(query : String)
        return "''" if query.blank?

        terms = query.split.compact
        tsquery_terms = terms.map { |term| tsquery_for_term(term) }
        tsquery_terms.join(any_word ? " || " : " && ")
      end

      def highlight(text : String, query : String)
        "ts_headline('#{dictionary}', #{text}, #{search_query(query)}, '#{headline_options}')"
      end

      def rank(document : String, query : String)
        "ts_rank(#{document}, #{search_query(query)}, #{normalization})"
      end

      private def tsquery_for_term(term : String)
        if negation && term.starts_with?("!")
          term = term[1..]
          negated = true
        end

        sanitized_term = term.gsub(DISALLOWED_TSQUERY_CHARACTERS, " ")
        term_sql = PG::EscapeHelper.escape_literal(sanitized_term)

        parts = [] of String
        parts << "!" if negated
        parts << "'"
        parts << term_sql
        parts << ":*" if prefix
        parts << "'"

        "to_tsquery('#{dictionary}', #{parts.join})"
      end

      private def headline_options
        return "" if highlight_options.empty?

        highlight_options.map do |key, value|
          case value
          when String
            "#{key} = '#{value}'"
          when Bool
            "#{key} = #{value}"
          else
            "#{key} = #{value}"
          end
        end.join(", ")
      end
    end
  end
end
