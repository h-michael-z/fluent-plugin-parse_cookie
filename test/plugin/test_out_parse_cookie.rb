require 'helper'
require 'rr'
require 'pry-byebug'
require 'fluent/plugin/out_parse_cookie'
require 'fluent/test/driver/output'
require 'fluent/test/helpers'

class ParseCookieOutputTest < Test::Unit::TestCase
  include Fluent::Test::Helpers

  COOKIE = 'temporary=tmp; empty=; __test=miahcel; array=123; array=abc; array=1a2b'.freeze

  def create_driver(conf)
    Fluent::Test::Driver::Output.new(Fluent::Plugin::ParseCookieOutput).configure(conf)
  end

  def setup
    Fluent::Test.setup
  end

  sub_test_case 'configure' do
    test 'configure' do
      d = create_driver(%(
        key cookie
      ))

      assert_equal 'cookie',          d.instance.key
      assert_equal 'parsed_cookie.',  d.instance.tag_prefix
      assert_equal false,             d.instance.remove_empty_array
    end
  end

  sub_test_case 'emit events' do
    test 'parse_cookie' do
      d = create_driver(%(
        key cookie
      ))
      time = event_time

      d.run(default_tag: 'test') do
        d.feed(time, { 'cookie' => COOKIE })
      end
      events = d.events
      event = events.first

      assert_equal 'parsed_cookie.test', event.first
      assert_equal ['tmp'],              event[2]['temporary']
      assert_equal [],                   event[2]['empty']
      assert_equal ['miahcel'],          event[2]['__test']
      assert_equal %w[123 abc 1a2b],     event[2]['array']
      assert_equal COOKIE,               event[2]['cookie']
    end

    test 'delete_cookie' do
      d = create_driver(%(
        key cookie
        remove_cookie true
      ))
      time = event_time

      d.run(default_tag: 'test') do
        d.feed(time, { 'cookie' => COOKIE })
      end
      events = d.events
      event = events.first

      assert_equal 'parsed_cookie.test', event.first
      assert_equal ['tmp'],              event[2]['temporary']
      assert_equal [],                   event[2]['empty']
      assert_equal ['miahcel'],          event[2]['__test']
      assert_equal %w[123 abc 1a2b],     event[2]['array']
      assert_equal nil,                  event[2]['cookie']
    end

    test 'add_tag_prefix' do
      d = create_driver(%(
        key cookie
        tag_prefix add_tag.
      ))
      time = event_time

      d.run(default_tag: 'test') do
        d.feed(time, { 'cookie' => COOKIE })
      end
      events = d.events
      event = events.first

      assert_equal 'add_tag.test', event.first
      assert_equal ['tmp'],              event[2]['temporary']
      assert_equal [],                   event[2]['empty']
      assert_equal ['miahcel'],          event[2]['__test']
      assert_equal %w[123 abc 1a2b],     event[2]['array']
      assert_equal COOKIE,               event[2]['cookie']
    end

    test 'remove_empty_array' do
      d = create_driver(%(
        key cookie
        remove_empty_array
      ))
      time = event_time

      d.run(default_tag: 'test') do
        d.feed(time, { 'cookie' => COOKIE })
      end
      events = d.events
      event = events.first

      assert_equal 'parsed_cookie.test', event.first
      assert_equal ['tmp'],              event[2]['temporary']
      assert_equal nil,                  event[2]['empty']
      assert_equal ['miahcel'],          event[2]['__test']
      assert_equal %w[123 abc 1a2b],     event[2]['array']
      assert_equal COOKIE,               event[2]['cookie']
    end

    test 'single_value_to_string' do
      d = create_driver(%(
        key cookie
        single_value_to_string true
      ))
      time = event_time

      d.run(default_tag: 'test') do
        d.feed(time, { 'cookie' => COOKIE })
      end
      events = d.events
      event = events.first

      assert_equal 'parsed_cookie.test', event.first
      assert_equal 'tmp',                event[2]['temporary']
      assert_equal [],                   event[2]['empty']
      assert_equal 'miahcel',            event[2]['__test']
      assert_equal %w[123 abc 1a2b],     event[2]['array']
      assert_equal COOKIE,               event[2]['cookie']
    end

    test 'remove_empty_array_single_value_to_string' do
      d = create_driver(%(
        key cookie
        remove_empty_array true
        single_value_to_string true
      ))
      time = event_time

      d.run(default_tag: 'test') do
        d.feed(time, { 'cookie' => COOKIE })
      end
      events = d.events
      event = events.first

      assert_equal 'parsed_cookie.test', event.first
      assert_equal 'tmp',                event[2]['temporary']
      assert_equal nil,                  event[2]['empty']
      assert_equal 'miahcel',            event[2]['__test']
      assert_equal %w[123 abc 1a2b],     event[2]['array']
      assert_equal COOKIE,               event[2]['cookie']
    end

    test 'sub_key' do
      d = create_driver(%(
        key cookie
        sub_key cookie_parsed
        remove_empty_array true
        single_value_to_string true
      ))
      time = event_time

      d.run(default_tag: 'test') do
        d.feed(time, { 'cookie' => COOKIE })
      end
      events = d.events
      event = events.first

      assert_equal 'parsed_cookie.test', event.first
      assert_equal 'tmp',                event[2]['cookie_parsed']['temporary']
      assert_equal nil,                  event[2]['cookie_parsed']['empty']
      assert_equal 'miahcel',            event[2]['cookie_parsed']['__test']
      assert_equal %w[123 abc 1a2b],     event[2]['cookie_parsed']['array']
      assert_equal COOKIE,               event[2]['cookie']
    end
  end
end
