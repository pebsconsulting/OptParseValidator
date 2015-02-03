module OptParseValidator
  # Implementation of the Array Option
  class OptArray < OptBase
    # @param [ String ] value
    #
    # @return [ Array ]
    def validate(value)
      super(value)
      value.split(separator)
    end

    # @return [ String ] The separator used to split the string into an array
    def separator
      attrs[:separator] || ','
    end
  end
end