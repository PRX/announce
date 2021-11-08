require "announce"
require "announce/message"

# publish, subscribe, & configure_broker are the 3 required methods for adapters
# the base adapter also has helpful base classes, but they are not necessary
# you can write an adapter from scratch, but these 3 class methods are required.
module Announce
  module Adapters
    class BaseAdapter
      class << self
        # required
        def publish(subject, action, body, options = {})
          topic = adapter_constantize(:topic).new(subject, action, options)
          msg =
            Announce::Message.new(subject: subject, action: action, body: body)
          topic.publish(msg.to_message, options)
        end

        # required
        def subscribe(worker_class, subject, actions = [], options = {})
          subscriber = adapter_constantize(:subscriber).new
          subscriber.subscribe(worker_class, subject, actions, options)
        end

        # required
        def configure_broker(options)
          broker_manager = adapter_constantize(:broker_manager).new(options)
          broker_manager.configure
        end

        def adapter_constantize(name)
          a_klass = Announce.options[:adapter].to_s.camelize
          klass = name.to_s.camelize
          "::Announce::Adapters::#{a_klass}Adapter::#{klass}".constantize
        end
      end

      class Subscriber
        def subscribe(worker_class, subject, actions, options)
          raise NotImplementedError.new("You must implement subscribe.")
        end
      end

      class BrokerManager
        attr_accessor :options

        # uses the configuration
        def initialize(options = {})
          @options = Announce.options.merge(options)
        end

        # actually configure the broker queues, topics, and subscriptions
        def configure
          raise NotImplementedError.new("You must implement configure.")
        end
      end

      class Destination
        attr_accessor :subject, :action, :options

        def publish(message, options = {})
          raise NotImplementedError.new("You must implement publish.")
        end

        def create
          raise NotImplementedError.new("You must implement create.")
        end

        def verify
          raise NotImplementedError.new("You must implement verify.")
        end

        def self.name_for(subject, action)
          [prefix, namespace, subject, action].join(delimiter)
        end

        def initialize(subject, action, options = {})
          @subject = subject
          @action = action
          @options = options || {}
        end

        def name(subject = @subject, action = @action)
          self.class.name_for(subject, action)
        end

        def self.prefix
          ::Announce.options[:queue_name_prefix]
        end

        def self.delimiter
          ::Announce.options[:queue_name_delimiter]
        end

        def self.app
          ::Announce.options[:app_name]
        end

        def self.namespace
          ::Announce.options[:namespace]
        end
      end

      class Topic < Destination; end

      class Queue < Destination
        def self.name_for(subject, action)
          [prefix, namespace, app, subject, action].join(delimiter)
        end
      end
    end
  end
end
