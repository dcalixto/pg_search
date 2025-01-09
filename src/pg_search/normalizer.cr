module PgSearch
  class Normalizer
    def initialize(@config : Configuration)
    end

    def add_normalization(expression : String) : String
      return expression unless @config.options[:ignoring]?.try(&.includes?(:accents))

      "unaccent(#{expression})"
    end

    def normalize_query(query : String) : String
      normalized = query
      if @config.options[:ignoring]?.try(&.includes?(:accents))
        normalized = remove_accents(normalized)
      end
      normalized
    end

    private def remove_accents(text : String) : String
      "unaccent(#{PG::EscapeHelper.escape_literal(text)})"
    end
  end
end
