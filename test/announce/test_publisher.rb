require 'test_helper'
require 'json'
require 'announce/publisher'
require 'announce/message'

describe Announce::Publisher do
  let (:publisher_class) { TestPublisher }
  let (:publisher) { publisher_class.new }

  before { clear_messages }

  it 'can publish a message' do
    publisher.publish('subject', 'action', { 'foo' => 'bar' }, {})
    _(last_message['body']['foo']).must_equal 'bar'
  end

  it 'can announce a message' do
    publisher.announce('subject', 'action', { 'foo' => 'bar' }, {})
    _(last_message['body']['foo']).must_equal 'bar'
  end
end
