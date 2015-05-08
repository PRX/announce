require 'test_helper'

describe Announce do

  before { Announce.options[:adapter] = 'test' }
  after { Announce.options[:adapter] = 'test' }

  it 'has a version number' do
    Announce::VERSION.wont_be_nil
  end

  it 'has options' do
    Announce.options.wont_be_nil
    Announce.options.must_be_instance_of Hash
  end

  it 'can configure options with hash and block' do
    Announce.configure() do |options|
      options.wont_be_nil
      options[:foo] = 'bar'
    end
    Announce.options[:foo].must_equal 'bar'
  end

  it 'will call configure on the broker' do
    Announce.configure_broker.must_equal true
  end

  it 'has default options' do
    defaults = Announce.default_options
    defaults[:name_prefix].must_equal 'development'
    defaults[:adapter].must_equal :inline
  end

  it 'creates a topic instance' do
    topic = Announce.topic('subject', 'action', {})
    topic.must_be_instance_of Announce::Adapters::TestAdapter::Topic
  end

  it 'subscribes a worker' do
    Announce.subscribe_worker(self.class, 'subject', ['action']).must_equal true
  end

  it 'loads an adapter class' do
    subscriber = Announce.adapter_constantize('subscriber')
    subscriber.must_be_instance_of Class
    subscriber.new.must_be_instance_of Announce::Adapters::TestAdapter::Subscriber
  end

  it 'has a default logger' do
    Announce.logger.wont_be_nil
    Announce.logger.must_be_instance_of Logger
  end

  it 'can set the logger' do
    Announce.logger = 'foo'
    Announce.logger.must_equal 'foo'
    Announce.logger = Logger.new('/dev/null')
  end
end
