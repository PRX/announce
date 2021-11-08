require "test_helper"

describe Announce do
  before(:each) { reset_announce }
  after(:each) { reset_announce }

  it "has a version number" do
    _(Announce::VERSION).wont_be_nil
  end

  it "has options" do
    _(Announce.options).wont_be_nil
    _(Announce.options).must_be_instance_of Hash
  end

  it "can configure options with hash and block" do
    Announce.configure do |options|
      _(options).wont_be_nil
      options[:foo] = "bar"
    end
    _(Announce.options[:foo]).must_equal "bar"
  end

  it "will call configure on the broker" do
    _(Announce.configure_broker).must_equal true
  end

  it "can publish a message" do
    Announce.publish("subject", "action", "body", {})
    _(last_message["body"]).must_equal "body"
  end

  it "can announce a message" do
    Announce.announce("subject", "action", "body", {})
    _(last_message["body"]).must_equal "body"
  end

  it "subscribes a worker" do
    _(Announce.subscribe(self.class, "subject", %w[action])).must_equal true
  end

  it "loads an adapter module" do
    adapter = Announce.adapter_class
    _(adapter).must_equal Announce::Adapters::TestAdapter
  end

  it "has a default logger" do
    _(Announce.logger).wont_be_nil
    _(Announce.logger).must_be_instance_of Logger
  end

  it "can set the logger" do
    Announce.logger = "foo"
    _(Announce.logger).must_equal "foo"
    Announce.logger = Logger.new("/dev/null")
  end
end
