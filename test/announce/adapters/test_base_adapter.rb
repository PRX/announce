require "test_helper"
require "announce/configuration"
require "announce/adapters/base_adapter"

describe Announce::Adapters::BaseAdapter do
  let(:base_adapter_class) { Announce::Adapters::BaseAdapter }

  it "can load an adapter class" do
    _(base_adapter_class.adapter_constantize(:topic)).must_equal(
      Announce::Adapters::TestAdapter::Topic
    )
  end

  it "can publish a message" do
    base_adapter_class.publish("subject", "action", "body", {})
    _(last_message["body"]).must_equal "body"
  end

  it "can subscribe" do
    base_adapter_class.subscribe(TestSubscriber, "subject", "action", {})
    sub = last_subscription
    _(sub[0]).must_equal TestSubscriber
  end

  it "can configure the broker" do
    reset_broker_config
    _(broker_configured?).must_equal false
    base_adapter_class.configure_broker({})
    _(broker_configured?).must_equal true
  end

  it "can configure the broker without creating queues or topics" do
    reset_broker_config
    _(broker_configured?).must_equal false
    base_adapter_class.configure_broker(verify_only: true)
    _(broker_configured?).must_equal true
  end

  describe "Subscriber" do
    let(:subscriber_class) { Announce::Adapters::BaseAdapter::Subscriber }
    let(:subscriber) { subscriber_class.new }

    it "does not implement subscribe" do
      _(
        -> { subscriber.subscribe(TestSubscriber, "subject", [], {}) }
      ).must_raise NotImplementedError
    end
  end

  describe "BrokerManager" do
    let(:broker_manager_class) do
      Announce::Adapters::BaseAdapter::BrokerManager
    end
    let(:broker_manager) { broker_manager_class.new }

    it "defaults to options from announce" do
      _(broker_manager.options).wont_be_nil
      _(broker_manager.options[:adapter]).must_equal "test"
    end

    it "takes options on initialize" do
      bm = broker_manager_class.new(foo: "bar")
      _(bm.options[:foo]).must_equal "bar"
    end

    it "does not implement configure" do
      _(-> { broker_manager.configure }).must_raise NotImplementedError
    end
  end

  describe "Destination" do
    let(:destination_class) { Announce::Adapters::BaseAdapter::Destination }
    let(:destination) do
      destination_class.new("subject", "action", foo: "bar")
    end

    it "does not implement publish" do
      _(
        -> { destination.publish("message", {}) }
      ).must_raise NotImplementedError
    end

    it "does not implement create" do
      _(-> { destination.create }).must_raise NotImplementedError
    end

    it "returns name for subject, action" do
      _(
        destination_class.name_for("subject", "action")
      ).must_equal "test_announce_subject_action"
    end

    it "initialize with subject, action, options" do
      d = destination_class.new("subject", "action", foo: "bar")
      _(d.subject).must_equal "subject"
      _(d.action).must_equal "action"
      _(d.options[:foo]).must_equal "bar"
    end
  end

  describe "Topic" do
    # exactly like destination, do nothing here
  end

  describe "Queue" do
    let(:queue_class) { Announce::Adapters::BaseAdapter::Queue }
    let(:queue) { queue_class.new("subject", "action", foo: "bar") }

    it "returns a queue name for subject, action, and this app" do
      _(
        queue_class.name_for("subject", "action")
      ).must_equal "test_announce_app_subject_action"
    end
  end
end
