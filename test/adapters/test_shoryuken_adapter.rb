require 'test_helper'
require 'announce/configuration'
require 'announce/adapters/base_adapter'
require 'announce/adapters/shoryuken_adapter'

describe Announce::Adapters::ShoryukenAdapter do

  before {
    Announce.options[:adapter] = :shoryuken
    Shoryuken.logger.level = Logger::UNKNOWN
    config_file = File.join(File.dirname(__FILE__), 'shoryuken.yml')
    Shoryuken::EnvironmentLoader.load(config_file: config_file)
  }

  after { reset_announce }

  let(:shoryuken_adapter_class) { Announce::Adapters::ShoryukenAdapter }

  it 'can load an adapter class' do
    shoryuken_adapter_class.adapter_constantize(:topic).must_equal Announce::Adapters::ShoryukenAdapter::Topic
  end

  describe 'Subscriber' do
    before {
      Shoryuken.queues.clear
      Shoryuken.worker_registry.clear
    }

    let(:subscriber_class) { Announce::Adapters::ShoryukenAdapter::Subscriber }
    let(:subscriber) { subscriber_class.new }

    it 'implements subscribe' do
      subscriber.subscribe(TestSubscriber, 'subject', ['create', 'delete'], {})
      Shoryuken.worker_registry.workers('test_app_subject_create').must_equal [TestSubscriber]
      Shoryuken.worker_registry.workers('test_app_subject_delete').must_equal [TestSubscriber]
    end
  end

  describe 'Topic' do

    before {
      Shoryuken.queues.clear
      Shoryuken.worker_registry.clear
    }

    let(:subscriber_class) { Announce::Adapters::ShoryukenAdapter::Subscriber }
    let(:subscriber) { subscriber_class.new }

    let(:topic_class) { Announce::Adapters::ShoryukenAdapter::Topic }
    let(:topic) { topic_class.new('subject', 'action') }

    before {
      subscriber.subscribe(TestSubscriber, 'subject', ['action'], {})
    }

    it 'implements publish' do
      msg = Announce::Message.new(subject: topic.subject, action: topic.action, body: { subject_id: 1 } )
      shoryuken_topic = Shoryuken::Client.topics('test_subject_action')
      shoryuken_topic.stub(:send_message, true) do
        topic.publish(msg.to_message)
      end
    end
  end
end
