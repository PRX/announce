require 'test_helper'
require 'announce/core_ext'

describe 'Announce core extensions' do

  describe 'Hash' do
    it 'will stringify keys' do
      {:key => 'val'}.stringify_keys.keys.first.must_equal 'key'
    end

    it 'will symbolize keys' do
      {'key' => 'val'}.symbolize_keys.keys.first.must_equal :key
    end

    it 'will deep symbolize keys' do
      {'key1' => { 'key2' => 'val' } }.deep_symbolize_keys[:key1].keys.first.must_equal :key2
    end

    it 'will slice key value pairs from a Hash' do
      {a: 1, b: 2, c: 3}.slice(:a, :c).keys.sort.must_equal [:a, :c]
    end
  end

  describe 'String' do
    it 'returns a class from a string' do
      class HelloWorld; end
      'HelloWorld'.constantize.must_equal HelloWorld
    end

    it 'changes string to camel case' do
      'this_is_sweet'.camelize.must_equal 'ThisIsSweet'
      'yeah/this_is_sweet'.camelize.must_equal 'Yeah::ThisIsSweet'
    end
  end
end
