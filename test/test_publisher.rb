require 'test_helper'
require 'json'
require 'announce/publisher'
require 'announce/message'

describe Announce::Publisher do

  class TestPublisher
    include Announce::Publisher
  end

  let (:publisher_class) { TestPublisher }
  let (:publisher) { publisher_class.new }

  before { clear_messages }

  it 'can publish a message' do
    publisher_class.publish('subject', 'action', { 'foo' => 'bar' }, {})
    last_message[:body]['foo'].must_equal 'bar'
  end
end
