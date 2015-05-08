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

  let (:publisher_class) { TestPublisher }
  let (:publisher) { publisher_class.new }

  before {
    Announce::Adapters::TestAdapter::Topic.published_messages.clear
  }

  it 'can publish a message' do
    publisher_class.publish('subject', 'action', { 'foo' => 'bar' }, {})
    message = JSON.parse(last_message.first)
    message['body']['foo'].must_equal 'bar'
  end
end
