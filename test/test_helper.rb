$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'announce'
require 'announce/adapters/test_adapter'

require 'minitest/autorun'

def last_message
  JSON.parse(Announce::Adapters::TestAdapter::Topic.published_messages.pop)
end

def clear_messages
  Announce::Adapters::TestAdapter::Topic.published_messages.clear
end

def last_subscription
  Announce::Adapters::TestAdapter::Subscriber.subscriptions.pop
end

def clear_subscriptions
  Announce::Adapters::TestAdapter::Subscriber.subscriptions.clear
end

def broker_configured?
  Announce::Adapters::TestAdapter::BrokerManager.configured?
end

def reset_broker_config
  Announce::Adapters::TestAdapter::BrokerManager.reset
end

def reset_announce
  Announce.logger = Logger.new('/dev/null')
  Announce.options[:adapter] = 'test'
  Announce.options[:name_prefix] = 'test'
  Announce.options[:app_name] = 'app'
end

reset_announce
