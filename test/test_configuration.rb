require 'test_helper'
require 'announce/configuration'

describe Announce::Configuration do

  before(:each) { Announce.options[:adapter] = 'test' }
  after(:each) { Announce.options[:adapter] = 'test' }

  it 'will return empty hash without a config file' do
    Announce::Configuration.configure(pub_sub_file: 'doesntexist.yml')
    Announce.options.wont_be_nil
  end

  it 'will return config from a file' do
    file = File.join(File.dirname(__FILE__), 'pub_sub.yml')
    Announce::Configuration.configure(pub_sub_file: file)
    Announce.options.wont_be_nil
    Announce.options[:subscribe].wont_be_nil
    Announce.options[:publish].wont_be_nil
  end
end
