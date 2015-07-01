# Gems
require 'addressable/uri'
require 'active_support/inflector'
# Standard Libs
require 'optparse'
require 'pathname'
# Custom Libs
require 'opt_parse_validator/errors'
require 'opt_parse_validator/hacks'
require 'opt_parse_validator/opts'
require 'opt_parse_validator/version'
require 'opt_parse_validator/options_file'

# Gem namespace
module OptParseValidator
  # Validator
  class OptParser < OptionParser
    attr_reader :symbols_used, :opts

    def initialize(banner = nil, width = 32, indent = ' ' * 4)
      @results      = {}
      @symbols_used = []
      @opts         = []

      super(banner, width, indent)
    end

    # @param [ OptBase ] options
    #
    # @return [ void ]
    def add(*options)
      options.each { |option| add_option(option) }
    end

    # @param [ OptBase ] opt
    #
    # @return [ void ]
    def add_option(opt)
      fail "The option is not an OptBase, #{opt.class} supplied" unless opt.is_a?(OptBase)
      fail "The option #{opt.to_sym} is already used !" if @symbols_used.include?(opt.to_sym)

      @opts << opt
      @symbols_used << opt.to_sym
      # Set the default option value if it exists
      @results[opt.to_sym] = opt.default unless opt.default.nil?

      on(*opt.option) do |arg|
        begin
          @results[opt.to_sym] = opt.normalize(opt.validate(arg))
        rescue => e
          # Adds the long option name to the message
          # e.g --proxy Invalid Scheme format.
          raise e.class, "#{opt.to_long} #{e}"
        end
      end
    end

    # @return [ Hash ]
    def results(argv = default_argv)
      load_options_files
      self.parse!(argv)
      post_processing

      @results
    end

    # Ensure that all required options are supplied
    # Should be overriden to modify the behavior
    #
    # @return [ Void ]
    def post_processing
      @opts.each do |opt|
        if opt.required?
          fail NoRequiredOption, "The option #{opt} is required" unless @results.key?(opt.to_sym)
        end

        next if opt.required_unless.empty?
        next if @results.key?(opt.to_sym)

        fail_msg = "One of the following options is required: #{opt}, #{opt.required_unless.join(', ')}"

        fail NoRequiredOption, fail_msg unless opt.required_unless.any? do |sym|
          @results.key?(sym)
        end
      end
    end
  end
end
