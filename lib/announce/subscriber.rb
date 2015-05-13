module Announce
  module Subscriber

    def self.included(base)
      base.class_eval do
        attr_accessor :subject, :action, :message
      end

      base.extend(ClassMethods)
    end

    module ClassMethods
      def subscribe_to(subject, actions=[], options = {})
        Announce.subscribe(self, subject, actions, options)
      end
    end

    def perform(*args)
      delegate_event(*args)
    end

    # For use in adapters to delegate to method named receive_subject_action
    def delegate_event(event)
      @message = event.deep_symbolize_keys
      @subject = message[:subject]
      @action = message[:action]

      if [message, subject, action].any? { |a| a.nil? }
        raise "Message, subject, and action are not all specified for '#{event.inspect}'"
      end

      if respond_to?(delegate_method)
        public_send(delegate_method, message[:body])
      else
        raise "`#{self.class.name}` is subscribed, but doesn't implement `#{delegate_method}` for '#{event.inspect}'"
      end
    end

    def delegate_method(message = @message)
      ['receive', message[:subject], message[:action]].join('_')
    end
  end
end
