require 'announce/adapters/base_adapter'

module Announce
  module Adapters
    class TestAdapter < BaseAdapter

      class Subscriber < BaseAdapter::Subscriber

        @@subscriptions = []

        def self.subscriptions
          @@subscriptions
        end

        def subscribe(worker_class, subject, actions, options)
          @@subscriptions << [worker_class, subject, actions, options]
          true
        end
      end

      class BrokerManager < BaseAdapter::BrokerManager
        @@configured = false

        def self.reset
          @@configured = false
        end

        def self.configured?
          @@configured
        end

        def configure
          @@configured = true
        end
      end

      class Topic < BaseAdapter::Topic

        @@published_messages = []

        def self.published_messages
          @@published_messages
        end

        def publish(message, options = {})
          @@published_messages << message
          true
        end

        def create
          true
        end
      end

      class Queue < BaseAdapter::Queue
        def create
          true
        end
      end
    end
  end
end
