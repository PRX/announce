require 'test_helper'
require 'announce/configuration'

describe Announce::Configuration do

  before(:each) { reset_announce }
  after(:each) { reset_announce }

  it 'has default options' do
    defaults = Announce::Configuration.default_options
    _(defaults[:queue_name_prefix]).must_equal 'test'
    _(defaults[:adapter]).must_equal :inline
  end

  it 'will return empty hash without a config file' do
    Announce::Configuration.configure(config_file: 'doesntexist.yml')
    _(Announce.options).wont_be_nil
  end

  it 'will return config from a file' do
    file = File.join(File.dirname(__FILE__), 'announce.yml')
    Announce::Configuration.configure(config_file: file)
    _(Announce.options).wont_be_nil
    _(Announce.options[:subscribe]).wont_be_nil
    _(Announce.options[:publish]).wont_be_nil
  end

  describe 'ActiveJob' do
    before {
      module ::ActiveJob
        module QueueAdapters
          class FakeAdapter
          end
        end
        class Base
          class << self
            def queue_name_prefix; 'activejob'; end
            def queue_name_delimiter; '-'; end
            def queue_adapter; ActiveJob::QueueAdapters::FakeAdapter; end
          end
        end
      end
    }

    after {
      Object.send(:remove_const, 'ActiveJob')
    }

    it 'loads config using ActiveJob defaults' do
      defaults = Announce::Configuration.default_options
      _(defaults[:queue_name_prefix]).must_equal 'activejob'
      _(defaults[:adapter]).must_equal 'fake'
    end
  end
end
