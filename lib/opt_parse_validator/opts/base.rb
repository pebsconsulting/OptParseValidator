module OptParseValidator
  # Base Option
  # This Option should not be called, children should be used.
  class OptBase
    attr_writer :required
    attr_reader :option, :attrs

    # @param [ Array ] option See OptionParser#on
    # @param [ Hash ] attrs
    # @option attrs [ Boolean ] :required
    # @options attrs [ Array<Symbol>, Symbol ] :required_unless
    # @option attrs [ Mixed ] :default The default value to use if the option is not supplied
    # @option attrs [ Mixed ] :value_if_empty The value to use if no arguments have been supplied
    # @option attrs [ Array<Symbol> ] :normalize See #normalize
    #
    # @note The :default and :normalize 'logics' are done in OptParseValidator::OptParser#add_option
    def initialize(option, attrs = {})
      @option = option
      @attrs  = attrs

      append_help_messages if respond_to?(:append_help_messages)
    end

    # @return [ Void ]
    def append_help_messages
      option << "Default: #{default}" if default
    end

    # @return [ Boolean ]
    def required?
      @required ||= attrs[:required]
    end

    def required_unless
      @required_unless ||= [*attrs[:required_unless]]
    end

    # @return [ Mixed ]
    def default
      attrs[:default]
    end

    # @return [ Array<Mixed> ]
    def choices
      attrs[:choices]
    end

    # @return [ Mixed ]
    def value_if_empty
      attrs[:value_if_empty]
    end

    # @param [ String ] value
    def validate(value)
      if value.nil? || value.to_s.empty?
        fail Error, 'Empty option value supplied' if value_if_empty.nil?
        return value_if_empty
      end
      value
    end

    # Apply each methods from attrs[:normalize] to the value if possible
    # User input should not be used in this attrs[:normalize]
    #
    # e.g: normalize: :to_sym will return the symbol of the value
    #      normalize: [:to_sym, :upcase] Will return the upercased symbol
    #
    # @param [ Mixed ] value
    #
    # @return [ Mixed ]
    def normalize(value)
      [*attrs[:normalize]].each do |method|
        next unless method.is_a?(Symbol)

        value = value.send(method) if value.respond_to?(method)
      end

      value
    end

    # @return [ Symbol ]
    def to_sym
      unless @symbol
        long_option = to_long

        fail Error, "Could not find option symbol for #{option}" unless long_option

        @symbol = long_option.gsub(/^--/, '').tr('-', '_').to_sym
      end
      @symbol
    end

    # @return [ String ] The raw long option (e.g: --proxy)
    def to_long
      option.each do |option_attr|
        if option_attr =~ /^--/
          return option_attr.gsub(/ .*$/, '')
                            .gsub(/\[[^\]]+\]/, '')
        end
      end
      nil
    end

    # @return [ String ]
    def to_s
      to_sym.to_s
    end

    # @return [ Array<String> ]
    def help_messages
      first_message_index = option.index { |e| e[0] != '-' }

      return [] unless first_message_index

      option[first_message_index..-1]
    end
  end
end
