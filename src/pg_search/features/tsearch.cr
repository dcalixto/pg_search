module PgSearch
  module Features
    class TSearch
      DISALLOWED_TSQUERY_CHARACTERS = /['?\\:''ʻʼ]/

      property dictionary : String
      property prefix : Bool

      def initialize(@dictionary : String = "english", @prefix : Bool = false)
      end

      def search_vector(text : String, weight : String? = nil)
        vector = "to_tsvector('#{dictionary}', #{text})"
        weight ? "setweight(#{vector}, '#{weight}')" : vector
      end

      def rank(columns, query)
        "ts_rank(to_tsvector('#{@dictionary}', #{columns}), to_tsquery('#{@dictionary}', '#{search_query(query)}'))"
      end

      def conditions(query, columns)
        "to_tsvector('#{@dictionary}', #{columns}) @@ to_tsquery('#{@dictionary}', '#{search_query(query)}')"
      end

      def highlight(text : String, query : String)
        "ts_headline('#{dictionary}', #{text}, #{search_query(query)}, '#{headline_options}')"
      end

      private def search_query(query)
        terms = query.split
        terms = terms.map { |term| "#{term}:*" } if @prefix
        terms.join(" & ")
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
