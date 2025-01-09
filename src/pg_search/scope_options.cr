module PgSearch
  class ScopeOptions
    getter config : Configuration
    getter model : Class
    getter feature_options : Hash(Symbol, Hash(Symbol, String | Bool | Float64))

    def initialize(@config)
      @model = config.model
      @feature_options = config.feature_options
    end

    def apply(query : String)
      rank_alias = "pg_search_rank"

      sql = String.build do |str|
        str << "SELECT #{model.table_name}.*, "
        str << rank_expression(query)
        str << " AS #{rank_alias} "
        str << "FROM #{model.table_name} "
        str << joins_clause
        str << "WHERE #{conditions(query)} "
        str << "ORDER BY #{rank_alias} DESC, #{order_within_rank}"
      end

      model.query_all(sql)
    end

    private def rank_expression(query)
      features = config.features.map do |feature_name|
        feature = feature_for(feature_name)
        feature.rank(query)
      end

      features.join(" + ")
    end

    private def conditions(query)
      features = config.features.reject { |f| feature_options[f]?.try(&.["sort_only"]?) }

      conditions = features.map do |feature_name|
        feature = feature_for(feature_name)
        feature.conditions(query)
      end

      conditions.join(" OR ")
    end

    private def feature_for(feature_name)
      case feature_name
      when :tsearch
        Features::TSearch.new
      when :trigram
        Features::Trigram.new
      when :dmetaphone
        Features::DMetaphone.new
      else
        raise "Unknown feature: #{feature_name}"
      end
    end

    private def joins_clause
      return "" unless config.associations?

      config.associations.map(&.join_sql).join(" ")
    end

    private def order_within_rank
      config.order_within_rank || "#{model.table_name}.id ASC"
    end
  end
end
