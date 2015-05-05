require 'minitest_helper'

describe Bottler do

  it 'has a version number' do
    ::Bottler::VERSION.wont_be_nil
  end

  it 'has a logger' do
    ::Bottler.logger.wont_be_nil
    ::Bottler.logger.must_be_instance_of Logger
  end

  it 'has options' do
    ::Bottler.options.wont_be_nil
    ::Bottler.options.must_be_instance_of Hash
  end
end
