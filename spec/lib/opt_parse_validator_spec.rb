# encoding: UTF-8

require 'spec_helper'

describe OptParseValidator do

  subject(:parser) { OptParseValidator.new }
  let(:verbose_opt) { OptBase.new(['-v', '--verbose']) }
  let(:url_opt)     { OptBase.new(['-u', '--url URL'], required: true) }

  describe '#add_option' do
    after do
      if @exception
        expect { parser.add_option(@option) }.to raise_error(@exception)
      else
        parser.add_option(@option)
        parser.symbols_used.should == @expected_symbols

        if @expected_required_opts
          parser.required_opts.should == @expected_required_opts
        end
      end
    end

    context 'when not an OptBase' do
      it 'raises an error' do
        @option    = 'just a string'
        @exception = 'The option is not an OptBase, String supplied'
      end
    end

    context 'when the option symbol is already used' do
      it 'raises an error' do
        @option    = verbose_opt
        @exception = 'The option verbose is already used !'
        parser.add_option(@option)
      end
    end

    context 'when a valid option' do
      let(:option) { OptBase.new(['-u', '--url URL']) }

      it 'sets the option' do
        @option = option
        @expected_symbols = [:url]
      end

      context 'when the option is required' do
        it 'adds it to the @required_opts' do
          @option                 = url_opt
          @expected_symbols       = [:url]
          @expected_required_opts = [@option]
        end
      end
    end
  end

  describe '#add' do
    context 'when not an Array<OptBase> or an OptBase' do
      after { expect { parser.add(*@options) }.to raise_error(@exception) }

      it 'raises an error when an Array<String>' do
        @options   = ['string', 'another one']
        @exception = 'The option is not an OptBase, String supplied'
      end
    end

    context 'when valid' do
      after do
        parser.add(*@options)
        parser.symbols_used.should == @expected_symbols

        if @expected_required_opts
          parser.required_opts.should == @expected_required_opts
        end
      end

      it 'adds the options' do
        @options                = [verbose_opt, url_opt]
        @expected_symbols       = [:verbose, :url]
        @expected_required_opts = [url_opt]
      end

      it 'adds the option' do
        @options          = verbose_opt
        @expected_symbols = [:verbose]
      end
    end
  end

  describe '#results' do
    after do
      parser.add(*options)

      if @expected
        parser.results(@argv).should == @expected
      else
        expect { parser.results(@argv) }.to raise_error(@exception)
      end
    end

    let(:options) { [verbose_opt, url_opt] }

    context 'when an option is required but not supplied' do
      it 'raises an error' do
        @exception = 'The option url is required'
        @argv      = ['-v']
      end
    end

    it 'returns the results' do
      @argv = ['--url', 'hello.com', '-v']
      @expected = { url: 'hello.com', verbose: true }
    end
  end

end