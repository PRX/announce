require 'test_helper'
require 'announce/message'

describe Announce::Message do

  before(:all) {
    ::Announce.options[:app_name] = 'test_app'
  }

  let (:bottle_message) { ::Announce::Message.new(subject: 'test', action: 'run', body: { foo: 'bar' } ) }

  it 'can contruct with a hash' do
    msg = ::Announce::Message.new(subject: 'test', action: 'run', body: { foo: 'bar' } )
    msg.wont_be_nil
    msg.options.wont_be_nil
    msg.options[:subject].must_equal 'test'
    msg.options[:action].must_equal 'run'
  end

  it 'can default options' do
    bottle_message.options[:message_id].wont_be_nil
    bottle_message.options[:sent_at].must_be_instance_of Time
    bottle_message.options[:app].must_equal 'test_app'
  end
end
