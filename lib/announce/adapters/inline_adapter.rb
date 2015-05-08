require 'announce/adapters/base_adapter'

module Announce
  module Adapters
    class InlineAdapter < BaseAdapter

      def self.subscriptions
        @@subscriptions ||= {}
      end

      class BrokerManager < BaseAdapter::BrokerManager
        def configure; end
      end

      class Subscriber < BaseAdapter::Subscriber
        def subscribe(worker_class, subject, actions, options)
          Array(actions).each do |action|
            queue_name = Queue.name_for(subject, action)
            InlineAdapter.subscriptions[queue_name] = worker_class
          end
        end
      end

      class Topic < BaseAdapter::Topic
        def publish(message, options = {})
          queue_name = Queue.name_for(subject, action)
          worker_class = InlineAdapter.subscriptions[queue_name]
          if defined?(::ActiveJob)
            job = worker_class.new(message)
            ::ActiveJob::Base.execute(job.serialize)
          else
            worker_class.new.perform(message)
          end
        end
      end

      class Queue < BaseAdapter::Queue
      end
    end
  end
end
