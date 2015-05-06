require 'minitest_helper'
require 'bottler/configuration'

describe Bottler::Configuration do

  it 'will return empty hash without a config file' do
    Bottler::Configuration.load(pub_sub_file: 'doesntexist.yml')
    Bottler.options.wont_be_nil
  end

  it 'will return config from a file' do
    file = File.join(File.dirname(__FILE__), 'pub_sub.yml')
    Bottler::Configuration.load(pub_sub_file: file)
    Bottler.options.wont_be_nil
    Bottler.options[:subscribe].wont_be_nil
    Bottler.options[:publish].wont_be_nil
  end
end
