require 'helper'
require 'rr'
require 'timecop'
require 'pry-byebug'
require 'fluent/plugin/out_parse_cookie'

class ParseCookieOutputTest < Test::Unit::TestCase

  COOKIE = 'temporary=tmp; empty=; __test=miahcel; array=123; array=abc; array=1a2b'

  def setup
    Fluent::Test.setup
    Timecop.freeze(@time)
  end

  teardown do
    Timecop.return
  end

  def create_driver(conf, tag)
    Fluent::Test::OutputTestDriver.new(
      Fluent::ParseCookieOutput, tag
    ).configure(conf)
  end

  def emit(conf, record, tag='test')
    d = create_driver(conf, tag)
    d.run {d.emit(record)}
    emits = d.emits
  end

  def test_configure
    d = create_driver(%[
      key                cookie
    ], "test")

    assert_equal 'cookie',          d.instance.key
    assert_equal 'parsed_cookie.',  d.instance.tag_prefix
    assert_equal false,             d.instance.remove_empty_array
  end

  def test_parse_cookie
    conf = %[
      key            cookie
    ]

    record = {
      'cookie' => COOKIE,
    }

    emits = emit(conf, record)

    emits.each_with_index do |(tag, time, record), i|
      assert_equal 'parsed_cookie.test',                     tag
      assert_equal ['tmp'],                                  record['temporary']
      assert_equal [],                                       record['empty']
      assert_equal ['miahcel'],                              record['__test']
      assert_equal ['123', 'abc', '1a2b'],                   record['array']
      assert_equal COOKIE,                                   record['cookie']
    end
  end

  def test_delete_cookie
    conf = %[
      key            cookie
      remove_cookie  true
    ]

    record = {
      'cookie' => COOKIE,
    }

    emits = emit(conf, record)

    emits.each_with_index do |(tag, time, record), i|
      assert_equal 'parsed_cookie.test',              tag
      assert_equal ['tmp'],       record['temporary']
      assert_equal [],            record['empty']
      assert_equal ['miahcel'],     record['__test']
      assert_equal ['123', 'abc', '1a2b'],     record['array']
      assert_equal nil,     record['cookie']
    end
  end

  def test_add_tag_prefix
    conf = %[
      key            cookie
      tag_prefix     add_tag.
    ]

    record = {
      'cookie' => COOKIE,
    }

    emits = emit(conf, record)

    emits.each_with_index do |(tag, time, record), i|
      assert_equal 'add_tag.test',              tag
      assert_equal ['tmp'],       record['temporary']
      assert_equal [],            record['empty']
      assert_equal ['miahcel'],     record['__test']
      assert_equal ['123', 'abc', '1a2b'],     record['array']
      assert_equal COOKIE,     record['cookie']
    end
  end

  def test_remove_empty_array
    conf = %[
      key                 cookie
      remove_empty_array  true
    ]

    record = {
      'cookie' => COOKIE,
    }

    emits = emit(conf, record)

    emits.each_with_index do |(tag, time, record), i|
      assert_equal 'parsed_cookie.test',              tag
      assert_equal ['tmp'],       record['temporary']
      assert_equal nil,            record['empty']
      assert_equal ['miahcel'],     record['__test']
      assert_equal ['123', 'abc', '1a2b'],     record['array']
      assert_equal COOKIE,     record['cookie']
    end
  end

  def test_single_value_to_string
    conf = %[
      key                     cookie
      single_value_to_string  true
    ]

    record = {
      'cookie' => COOKIE,
    }

    emits = emit(conf, record)

    emits.each_with_index do |(tag, time, record), i|
      assert_equal 'parsed_cookie.test',              tag
      assert_equal 'tmp',       record['temporary']
      assert_equal [],            record['empty']
      assert_equal 'miahcel',     record['__test']
      assert_equal ['123', 'abc', '1a2b'],     record['array']
      assert_equal COOKIE,     record['cookie']
    end
  end

  def test_remove_empty_array_single_value_to_string
    conf = %[
      key                     cookie
      remove_empty_array      true
      single_value_to_string  true
    ]

    record = {
      'cookie' => COOKIE,
    }

    emits = emit(conf, record)

    emits.each_with_index do |(tag, time, record), i|
      assert_equal 'parsed_cookie.test',              tag
      assert_equal 'tmp',       record['temporary']
      assert_equal nil,            record['empty']
      assert_equal 'miahcel',     record['__test']
      assert_equal ['123', 'abc', '1a2b'],     record['array']
      assert_equal COOKIE,     record['cookie']
    end
  end
end