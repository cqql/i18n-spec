module I18nSpec
  class LocaleFile
    PLURALIZATION_KEYS = %w{zero one two few many other}

    attr_accessor :path
    attr_reader :errors

    attr_reader :locale
    attr_reader :translations

    def initialize path, hash
      if hash.keys.size > 1
        raise MultipleTopLevelKeys
      end

      @path = path
      @locale = hash.keys.first
      @translations = hash[@locale]
      @errors = { }
    end

    def locale_tag
      @locale_tag ||= ISO::Tag.new(locale)
    end

    def invalid_pluralization_keys
      filter = lambda do |hash|
        invalid_nodes = { }

        if hash.is_a? Hash
          hash.each do |key, value|
            if value.is_a? Hash
              if has_pluralization_keys?(value) && !is_pluralization?(value)
                invalid_nodes[key] = 0
              else
                invalid_subnodes = filter.call value

                invalid_nodes[key] = invalid_subnodes if !invalid_subnodes.empty?
              end
            end
          end
        end

        invalid_nodes
      end

      keys_to_dot_notation filter.call(@translations)
    end

    def missing_pluralization_keys
      is_incomplete_pluralization = lambda do |node|
        all_keys = locale_tag.language.plural_rule_names
        missing_keys = all_keys - node.keys

        !missing_keys.empty? && all_keys != missing_keys
      end

      filter = lambda do |hash|
        invalid_nodes = { }

        if hash.is_a? Hash
          hash.each do |key, value|
            if value.is_a? Hash
              if is_incomplete_pluralization.call value
                invalid_nodes[key] = locale_tag.language.plural_rule_names - value.keys
              else
                invalid_nodes[key] = filter.call value
              end
            end
          end
        end

        invalid_nodes
      end

      flatten_keys filter.call(@translations)
    end

    def self.is_parseable? path
      begin
        from_file path

        true
      rescue SyntaxError
        false
      end
    end

    def has_one_top_level_namespace?
      translations.keys.size == 1
    end

    def is_named_like_locale?
      locale == File.basename(@path, File.extname(@path))
    end

    def is_a_complete_translation_of? locale_file
      missing_keys_from_locale(locale_file).empty?
    end

    def missing_keys_from_locale locale_file
      locale_file.keys - keys
    end

    def keys
      keys_to_dot_notation @translations
    end

    def self.from_file path
      content = IO.read(path)

      new path, YAML.load(content)
    end

    class InvalidLocale < Exception

    end

    class MultipleTopLevelKeys < InvalidLocale

    end

    protected

    def flatten_keys hash, prefix = []
      flattened = { }

      hash.each do |key, value|
        if value.is_a? Hash
          flattened = flattened.merge flatten_keys(value, prefix + [key])
        else
          flattened[(prefix + [key]).join(".")] = value
        end
      end

      flattened
    end

    def keys_to_dot_notation hash, prefix = []
      keys = []

      hash.each do |key, value|
        if value.is_a?(Hash) && !is_pluralization?(value)
          keys += keys_to_dot_notation value, prefix + [key]
        else
          keys += [(prefix + [key]).join(".")]
        end
      end

      keys
    end

    def is_pluralization? node
      node.keys.all? { |key| PLURALIZATION_KEYS.include?(key) }
    end

    def has_pluralization_keys? node
      node.keys.any? { |key| PLURALIZATION_KEYS.include?(key) }
    end

    def pluralization_data?(data)
      keys = data.keys.map(&:to_s)
      keys.any? { |k| PLURALIZATION_KEYS.include?(k) }
    end
  end
end
