$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'announce'
require 'announce/adapters/test_adapter'

require 'minitest/autorun'

Announce.logger = Logger.new('/dev/null')

Announce.options[:adapter] = 'test'
