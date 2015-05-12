require 'test_helper'
require 'announce/configuration'
require 'announce/adapters/base_adapter'

describe Announce::Adapters::BaseAdapter do
  let(:base_adapter_class) { Announce::Adapters::BaseAdapter }

  it 'can load an adapter class' do
    base_adapter_class.adapter_constantize(:topic).must_equal Announce::Adapters::TestAdapter::Topic
  end

  it 'can publish a message' do
    base_adapter_class.publish('subject', 'action', 'body', {})
    last_message['body'].must_equal 'body'
  end

  it 'can subscribe' do
    base_adapter_class.subscribe(TestSubscriber, 'subject', 'action', {})
    sub = last_subscription
    sub[0].must_equal TestSubscriber
  end

  it 'can configure the broker' do
    reset_broker_config
    broker_configured?.must_equal false
    base_adapter_class.configure_broker({})
    broker_configured?.must_equal true
  end

  describe 'Subscriber' do
    let(:subscriber_class) { Announce::Adapters::BaseAdapter::Subscriber }
    let(:subscriber) { subscriber_class.new }

    it 'does not implement subscribe' do
      lambda do
        subscriber.subscribe(TestSubscriber, 'subject', [], {})
      end.must_raise NotImplementedError
    end
  end

  describe 'BrokerManager' do
    let(:broker_manager_class) { Announce::Adapters::BaseAdapter::BrokerManager }
    let(:broker_manager) { broker_manager_class.new }

    it 'defaults to options from announce' do
      broker_manager.options.wont_be_nil
      broker_manager.options[:adapter].must_equal 'test'
    end

    it 'takes options on initialize' do
      bm = broker_manager_class.new(foo: 'bar')
      bm.options[:foo].must_equal 'bar'
    end

    it 'does not implement configure' do
      lambda do
        broker_manager.configure
      end.must_raise NotImplementedError
    end
  end

  describe 'Destination' do
    let(:destination_class) { Announce::Adapters::BaseAdapter::Destination }
    let(:destination) { destination_class.new('subject', 'action', { foo: 'bar' } ) }

    it 'does not implement publish' do
      lambda do
        destination.publish('message', {})
      end.must_raise NotImplementedError
    end

    it 'does not implement create' do
      lambda do
        destination.create
      end.must_raise NotImplementedError
    end

    it 'returns name for subject, action' do
      destination_class.name_for('subject', 'action').must_equal 'test_announce_subject_action'
    end

    it 'initialize with subject, action, options' do
      d = destination_class.new('subject', 'action', { foo: 'bar' } )
      d.subject.must_equal 'subject'
      d.action.must_equal 'action'
      d.options[:foo].must_equal 'bar'
    end
  end

  describe 'Topic' do
    # exactly like destination, do nothing here
  end

  describe 'Queue' do
    let(:queue_class) { Announce::Adapters::BaseAdapter::Queue }
    let(:queue) { queue_class.new('subject', 'action', { foo: 'bar' } ) }

    it 'returns a queue name for subject, action, and this app' do
      q = queue_class.name_for('subject', 'action').must_equal 'test_announce_app_subject_action'
    end
  end
end
