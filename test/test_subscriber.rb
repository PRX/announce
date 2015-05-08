require 'test_helper'
require 'announce/subscriber'

describe Announce::Subscriber do

  before { clear_subscriptions }

  let (:subscriber_class) { TestSubscriber }
  let (:subscriber) { subscriber_class.new }
  let (:event_message) { { subject: 'subject', action: 'action', body: { foo: 'bar' } } }

  it 'can subscribe to subject and actions' do
    subscriber_class.subscribe_to('subject', ['create', 'delete'], { foo: 'bar' } )
    sub = last_subscription
    sub[0].must_equal subscriber_class
    sub[1].must_equal 'subject'
    sub[2].must_equal ['create', 'delete']
    sub[3][:foo].must_equal 'bar'
  end

  it 'determines delegate method from message' do
    subscriber.delegate_method(event_message).must_equal 'receive_subject_action'
  end

  it 'calling delegate method save current message info' do
    subscriber.delegate_event(event_message)
    subscriber.subject.must_equal 'subject'
    subscriber.action.must_equal 'action'
    subscriber.message.must_equal event_message
  end

  it 'calling delegate method save current message info' do
    subscriber.delegate_event(event_message)
    em = subscriber_class.received.pop
    em.must_equal event_message[:body]
  end
end
