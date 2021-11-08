require "test_helper"
require "announce/message"

describe Announce::Message do
  let (:announce_message) do
    ::Announce::Message.new(
      subject: "test", action: "run", body: { foo: "bar" }
    )
  end

  it "can contruct with a hash" do
    msg =
      ::Announce::Message.new(
        subject: "test", action: "run", body: { foo: "bar" }
      )
    _(msg).wont_be_nil
    _(msg.options).wont_be_nil
    _(msg.options["subject"]).must_equal "test"
    _(msg.options["action"]).must_equal "run"
  end

  it "can default options" do
    _(announce_message.options["message_id"]).wont_be_nil
    _(announce_message.options["sent_at"]).must_be_instance_of Time
    _(announce_message.options["app"]).must_equal "app"
  end

  it "can serialize to json" do
    msg = JSON.parse(announce_message.to_json)
    _(msg["app"]).must_equal "app"
  end

  it "can become a message hash" do
    _(announce_message.to_message).must_be_instance_of Hash
  end
end
