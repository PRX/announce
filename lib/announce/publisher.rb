require 'shoryuken'
require 'announce'
require 'announce/message'

module Announce
  module Publisher

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods

      def publish(subject, action, body, options = {})
        topic = Announce.topic(subject, action, options)
        msg = message(subject, action, body)
        topic.publish(msg.to_json, options)
      end

      def message(subject, action, body)
        Announce::Message.new(subject: subject, action: action, body: body)
      end
    end
  end
end
