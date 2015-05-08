require 'test_helper'
require 'json'
require 'announce/publisher'
require 'announce/message'

describe Announce::Publisher do

  class TestPublisher
    include Announce::Publisher
  end

  def last_message
    Announce::Adapters::TestAdapter::Topic.published_messages.pop
  end

  let (:publisher) { TestPublisher }

  it 'creates a message object' do
    message = publisher.message('subject', 'action', { 'foo' => 'bar' })
    message.must_be_instance_of Announce::Message
  end

  it 'can publish a message' do
    publisher.publish('subject', 'action', { 'foo' => 'bar' }, {})
    message = JSON.parse(last_message.first)
    message['body']['foo'].must_equal 'bar'
  end
end
