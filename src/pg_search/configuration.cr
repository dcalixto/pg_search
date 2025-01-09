module PgSearch
  class Configuration
    getter model : DB::Serializable.class
    getter options : Hash(Symbol, String | Symbol | Hash(Symbol, String | Bool))

    def initialize(@options, @model : DB::Serializable.class)
      @options = default_options.merge(options)
      validate_options!
    end

    def self.alias(*parts : String) : String
      name = parts.compact.join("_")
      "pg_search_#{Digest::SHA256.hexdigest(name)[0..31]}"
    end

    class Column
      getter name : String
      getter weight : String?

      def initialize(@name, @weight, @model)
      end

      def full_name
        "#{table_name}.#{column_name}"
      end

      def to_sql
        "COALESCE((#{expression})::text, '')"
      end
    end

    class Association
      getter columns : Array(ForeignColumn)

      def initialize(@model, @name : Symbol, column_names)
        @columns = [] of ForeignColumn
        column_names.each do |column_name, weight|
          @columns << ForeignColumn.new(column_name.to_s, weight, @model, self)
        end
      end

      def join_sql(primary_key)
        "LEFT OUTER JOIN #{table_name} ON #{table_name}.id = #{primary_key}"
      end
    end

    class ForeignColumn < Column
      def initialize(@name : String, @weight : String?, @model, @association : Association)
        super(@name, @weight, @model)
      end
    end

    private def default_options
      {
        using:    :tsearch,
        ignoring: [] of Symbol,
      }
    end

    private def validate_options!
      unless options[:against]? || options[:associated_against]?
        raise ArgumentError.new("Search scope must have :against or :associated_against options")
      end
    end
  end
end
