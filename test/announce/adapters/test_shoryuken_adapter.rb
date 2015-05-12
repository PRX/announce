require 'test_helper'
require 'announce/configuration'
require 'announce/adapters/base_adapter'
require 'announce/adapters/shoryuken_adapter'
require 'ostruct'

describe Announce::Adapters::ShoryukenAdapter do

  before {
    Announce.options[:adapter] = :shoryuken
    Shoryuken.logger.level = Logger::ERROR
    config_file = File.join(File.dirname(__FILE__), 'shoryuken.yml')
    Shoryuken::EnvironmentLoader.load(config_file: config_file)
  }

  after { reset_announce }

  let(:shoryuken_adapter_class) { Announce::Adapters::ShoryukenAdapter }

  it 'can load an adapter class' do
    shoryuken_adapter_class.adapter_constantize(:topic).must_equal Announce::Adapters::ShoryukenAdapter::Topic
  end

  describe 'BrokerManager' do
    let(:broker_options) do
      {
        publish: { subject: ['action'] },
        subscribe: { subject: ['action'] }
      }
    end
    let(:manager_class) { Announce::Adapters::ShoryukenAdapter::BrokerManager }
    let(:manager) { manager_class.new(broker_options) }

    it 'configures for publish and subscribe' do
      manager.stub(:configure_publishing, true) do
        manager.stub(:configure_subscribing, true) do
          manager.configure.must_equal true
        end
      end
    end

    it 'can configure topics for publishing' do
      Shoryuken::Client.sns.stub(:create_topic, { topic_arn: 'arn' } ) do
        manager.configure_publishing.must_equal true
      end
    end

    it 'can configure queues, topics, and subscriptions for receiving' do

      sns = Minitest::Mock.new
      sns.expect(:config, {region: 'us-east-1'})
      sns.expect(:create_topic, { topic_arn: 'arn' }, [Hash])
      sns.expect(:subscribe, { subscription_arn: 'arn' }, [Hash])
      sns.expect(:set_subscription_attributes, true, [Hash])

      sqs = Minitest::Mock.new
      sqs.expect(:config, {region: 'us-east-1'})
      sqs.expect(:config, {region: 'us-east-1'})
      sqs.expect(:config, {region: 'us-east-1'})
      sqs.expect(:create_queue, { queue_url: 'url' }, [Hash])
      sqs.expect(:create_queue, { queue_url: 'url' }, [Hash])

      qua = OpenStruct.new(attributes: { 'QueueArn' => 'arn' })
      sqs.expect(:get_queue_attributes, qua, [Hash])

      Shoryuken::Client.stub(:sns, sns) do
        Shoryuken::Client.stub(:sqs, sqs) do
          manager.configure_subscribing
        end
      end
    end
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
      Shoryuken.worker_registry.workers('test_announce_app_subject_create').must_equal [TestSubscriber]
      Shoryuken.worker_registry.workers('test_announce_app_subject_delete').must_equal [TestSubscriber]
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
      shoryuken_topic = Shoryuken::Client.topics('test_announce_subject_action')
      shoryuken_topic.stub(:send_message, true) do
        topic.publish(msg.to_message)
      end
    end

    it 'can create the topic in SNS' do
      topic.sns.stub(:create_topic, {topic_arn: 'arn:aws:sns:us-east-1:account_id:test_announce_app_subject_action'}) do
        sub = topic.create.must_equal 'arn:aws:sns:us-east-1:account_id:test_announce_app_subject_action'
      end
    end

    it 'returns the ARN' do
      topic.arn.must_equal 'arn:aws:sns:us-east-1:123456789012:test_announce_subject_action'
    end
  end
end
