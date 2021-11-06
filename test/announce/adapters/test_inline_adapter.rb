require 'test_helper'
require 'announce/configuration'
require 'announce/adapters/base_adapter'
require 'announce/adapters/inline_adapter'

describe Announce::Adapters::InlineAdapter do

  before { Announce.options[:adapter] = :inline }
  after { reset_announce }

  let(:inline_adapter_class) { Announce::Adapters::InlineAdapter }

  it 'can load an adapter class' do
    _(inline_adapter_class.adapter_constantize(:topic)).must_equal Announce::Adapters::InlineAdapter::Topic
  end

  describe 'Subscriber' do
    before { Announce::Adapters::InlineAdapter.subscriptions.clear }

    let(:subscriber_class) { Announce::Adapters::InlineAdapter::Subscriber }
    let(:subscriber) { subscriber_class.new }

    it 'implements subscribe' do
      subscriber.subscribe(TestSubscriber, 'subject', ['create', 'delete'], {})
      subs = Announce::Adapters::InlineAdapter.subscriptions
      _(subs['test_announce_app_subject_create']).must_equal TestSubscriber
      _(subs['test_announce_app_subject_delete']).must_equal TestSubscriber
    end
  end

  describe 'Topic' do
    let(:subscriber_class) { Announce::Adapters::InlineAdapter::Subscriber }
    let(:subscriber) { subscriber_class.new }

    let(:topic_class) { Announce::Adapters::InlineAdapter::Topic }
    let(:topic) { topic_class.new('subject', 'action') }

    before {
      Announce::Adapters::InlineAdapter.subscriptions.clear
      subscriber.subscribe(TestSubscriber, 'subject', ['action'], {})
    }

    it 'implements publish' do
      msg = Announce::Message.new(subject: topic.subject, action: topic.action, body: { subject_id: 1 } )
      topic.publish(msg.to_message)
      received = TestSubscriber.received.pop
      _(received[:subject_id]).must_equal 1
    end
  end
end
