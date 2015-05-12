require 'simplecov'
SimpleCov.start

if ENV['TRAVIS']
  require 'coveralls'
  Coveralls.wear!
end

ENV['APP_ENV'] = 'test'
ENV['AWS_ACCESS_KEY_ID'] = 'ANDTHISISFAKEOKAY'
ENV['AWS_SECRET_ACCESS_KEY'] = 'andthisisalsoveryfakesodontbefooledandtrytouseit'
ENV['AWS_REGION'] = 'us-east-1'
ENV['AWS_ACCOUNT_ID'] = '123456789012'

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'announce'
require 'announce/adapters/test_adapter'

require 'minitest/autorun'
require 'minitest/spec'
require 'minitest/pride'

class TestPublisher
  include Announce::Publisher
end

class TestSubscriber

  include Shoryuken::Worker
  include Announce::Subscriber

  @@received = []

  def self.received
    @@received
  end

  def receive_subject_action(message)
    @@received << message
  end
end

def last_message
  Announce::Adapters::TestAdapter::Topic.published_messages.pop
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
  Announce.options[:queue_name_prefix] = 'test'
  Announce.options[:app_name] = 'app'
end

reset_announce
