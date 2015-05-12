require 'test_helper'
require 'announce/configuration'

describe Announce::Configuration do

  before(:each) { reset_announce }
  after(:each) { reset_announce }

  it 'has default options' do
    defaults = Announce::Configuration.default_options
    defaults[:queue_name_prefix].must_equal 'test'
    defaults[:adapter].must_equal :inline
  end

  it 'will return empty hash without a config file' do
    Announce::Configuration.configure(config_file: 'doesntexist.yml')
    Announce.options.wont_be_nil
  end

  it 'will return config from a file' do
    file = File.join(File.dirname(__FILE__), 'announce.yml')
    Announce::Configuration.configure(config_file: file)
    Announce.options.wont_be_nil
    Announce.options[:subscribe].wont_be_nil
    Announce.options[:publish].wont_be_nil
  end
end
