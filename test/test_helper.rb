ENV['RAILS_ENV'] ||= 'test'

require 'simplecov'
SimpleCov.start 'rails'

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
require 'announce/testing'

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

include Announce::Testing

reset_announce
