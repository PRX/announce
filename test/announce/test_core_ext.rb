require "test_helper"
require "announce/core_ext"

describe "Announce core extensions" do
  describe "Hash" do
    it "will stringify keys" do
      _({ key: "val" }.stringify_keys.keys.first).must_equal "key"
    end

    it "will symbolize keys" do
      _({ "key" => "val" }.symbolize_keys.keys.first).must_equal :key
    end

    it "will deep symbolize keys" do
      _(
        { "key1" => { "key2" => "val" } }.deep_symbolize_keys[:key1].keys.first
      ).must_equal :key2
    end

    it "will slice key value pairs from a Hash" do
      _({ a: 1, b: 2, c: 3 }.slice(:a, :c).keys.sort).must_equal %i[a c]
    end
  end

  describe "String" do
    it "returns a class from a string" do
      class HelloWorld; end
      _("HelloWorld".constantize).must_equal HelloWorld
    end

    it "changes string to camel case" do
      _("this_is_sweet".camelize).must_equal "ThisIsSweet"
      _("yeah/this_is_sweet".camelize).must_equal "Yeah::ThisIsSweet"
    end

    it "changes CamelCase to under_score" do
      _("ThisIsSweet".underscore).must_equal "this_is_sweet"
      _("Yeah::ThisIsSweet".underscore).must_equal "yeah/this_is_sweet"
    end
  end
end
