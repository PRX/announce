require "test_helper"
require "announce/configuration"
require "announce/adapters/base_adapter"
require "announce/adapters/shoryuken_adapter"
require "ostruct"

describe Announce::Adapters::ShoryukenAdapter do
  before do
    Announce.options[:adapter] = :shoryuken
    Shoryuken.logger.level = Logger::ERROR
    Shoryuken.queues.clear
    config_file = File.join(File.dirname(__FILE__), "shoryuken.yml")
    Shoryuken::EnvironmentLoader.load(config_file: config_file)
  end

  after { reset_announce }

  let(:shoryuken_adapter_class) { Announce::Adapters::ShoryukenAdapter }

  it "can load an adapter class" do
    _(
      shoryuken_adapter_class.adapter_constantize(:topic)
    ).must_equal Announce::Adapters::ShoryukenAdapter::Topic
  end

  describe "BrokerManager" do
    let(:broker_options) do
      { publish: { subject: %w[action] }, subscribe: { subject: %w[action] } }
    end
    let(:manager_class) { Announce::Adapters::ShoryukenAdapter::BrokerManager }
    let(:manager) { manager_class.new(broker_options) }

    it "configures for publish and subscribe" do
      manager.stub(:configure_publishing, true) do
        manager.stub(:configure_subscribing, true) do
          _(manager.configure).must_equal true
        end
      end
    end

    it "can configure topics for publishing" do
      Shoryuken::Client.sns.stub(:create_topic, { topic_arn: "arn" }) do
        _(manager.configure_publishing).must_equal true
      end
    end

    it "can configure queues, topics, and subscriptions for receiving" do
      sns = Minitest::Mock.new
      sns.expect(:config, { region: "us-east-1" })
      sns.expect(:create_topic, { topic_arn: "arn" }, [Hash])
      sns.expect(:subscribe, { subscription_arn: "arn" }, [Hash])
      sns.expect(:set_subscription_attributes, true, [Hash])

      sqs = Minitest::Mock.new
      sqs.expect(:config, { region: "us-east-1" })
      sqs.expect(:config, { region: "us-east-1" })
      sqs.expect(:config, { region: "us-east-1" })
      sqs.expect(:create_queue, { queue_url: "url" }, [Hash])
      sqs.expect(:create_queue, { queue_url: "url" }, [Hash])

      qua = OpenStruct.new(attributes: { "QueueArn" => "arn" })
      sqs.expect(:get_queue_attributes, qua, [Hash])

      Shoryuken::Client.stub(:sns, sns) do
        Shoryuken::Client.stub(:sqs, sqs) { manager.configure_subscribing }
      end
    end

    it "verifies configuration" do
      logging_io = StringIO.new
      Announce.logger = Logger.new(logging_io)
      verify_manager =
        manager_class.new(broker_options.merge({ verify_only: true }))
      verify_manager.configure
      Announce.logger = Logger.new("/dev/null")
      logging = logging_io.string
      _(logging).must_match(
        /Verify SQS Queue: arn:aws:sqs:.*:test_announce_app_subject_action/
      )
      _(logging).must_match(
        /Verify SNS Topic: arn:aws:sns:.*:test_announce_subject_action/
      )
      _(logging).must_match(/Verify Subscription/)
      _(logging).must_match(
        /from SNS Topic: arn:aws:sns:.*:test_announce_subject_action/
      )
      _(logging).must_match(
        /to SQS Queue: arn:aws:sqs:.*:test_announce_app_subject_action/
      )
    end
  end

  describe "Subscriber" do
    before do
      Shoryuken.queues.clear
      Shoryuken.worker_registry.clear
    end

    let(:subscriber_class) { Announce::Adapters::ShoryukenAdapter::Subscriber }
    let(:subscriber) { subscriber_class.new }

    it "implements subscribe" do
      subscriber.subscribe(TestSubscriber, "subject", %w[create delete], {})
      _(
        Shoryuken.worker_registry.workers("test_announce_app_subject_create")
      ).must_equal [TestSubscriber]
      _(
        Shoryuken.worker_registry.workers("test_announce_app_subject_delete")
      ).must_equal [TestSubscriber]
    end
  end

  describe "Topic" do
    before do
      Shoryuken.queues.clear
      Shoryuken.worker_registry.clear
    end

    let(:subscriber_class) { Announce::Adapters::ShoryukenAdapter::Subscriber }
    let(:subscriber) { subscriber_class.new }

    let(:topic_class) { Announce::Adapters::ShoryukenAdapter::Topic }
    let(:topic) { topic_class.new("subject", "action") }

    before { subscriber.subscribe(TestSubscriber, "subject", %w[action], {}) }

    it "implements publish" do
      msg =
        Announce::Message.new(
          subject: topic.subject, action: topic.action, body: { subject_id: 1 }
        )
      shoryuken_topic = Shoryuken::Client.topics("test_announce_subject_action")
      shoryuken_topic.stub(:send_message, true) do
        topic.publish(msg.to_message)
      end
    end

    it "can create the topic in SNS" do
      test_arn =
        "arn:aws:sns:us-east-1:account_id:test_announce_app_subject_action"
      topic.sns.stub(:create_topic, { topic_arn: test_arn }) do
        _(topic.create).must_equal test_arn
      end
    end

    it "returns the ARN" do
      arn = "arn:aws:sns:us-east-1:123456789012:test_announce_subject_action"
      _(topic.arn).must_equal arn
    end
  end
end
