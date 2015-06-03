require 'announce'
require 'announce/adapters/test_adapter'

module Announce
  module Testing

    def published_messages
      Announce::Adapters::TestAdapter::Topic.published_messages
    end

    def last_message
      published_messages.last
    end

    def clear_messages
      published_messages.clear
    end

    def subscriptions
      Announce::Adapters::TestAdapter::Subscriber.subscriptions
    end

    def last_subscription
      subscriptions.last
    end

    def clear_subscriptions
      subscriptions.clear
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
      clear_messages
    end
  end
end
