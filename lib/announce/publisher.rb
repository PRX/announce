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
        Announce.publish(subject, action, body, options)
      end
    end
  end
end
