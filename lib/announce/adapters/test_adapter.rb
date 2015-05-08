require 'announce/adapters/base_adapter'

module Announce
  module Adapters
    module TestAdapter

      class Subscriber < Announce::Adapters::BaseAdapter::Subscriber
        def subscribe(worker_class, subject, actions, options)
          true
        end
      end

      class BrokerManager < Announce::Adapters::BaseAdapter::BrokerManager
        def configure
          true
        end
      end

      class Topic < Announce::Adapters::BaseAdapter::Topic

        @@published_messages = []

        def self.published_messages
          @@published_messages
        end

        def publish(message, options = {})
          @@published_messages << [message, options]
          true
        end

        def create
          true
        end
      end

      class Queue < Announce::Adapters::BaseAdapter::Queue
        def create
          true
        end
      end
    end
  end
end
