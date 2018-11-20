module Fluent
  class ParseCookieOutput < Output
    Fluent::Plugin.register_output('parse_cookie', self)
    config_param :key, :string
    config_param :tag_prefix,             :string, default: 'parsed_cookie.'
    config_param :remove_empty_array,     :bool, default: false
    config_param :single_value_to_string, :bool, default: false
    config_param :remove_cookie,          :bool, default: false
    config_param :sub_key,                :string, default: nil

    def initialize
      super
      require 'cgi'
    end

    # Define `log` method for v0.10.42 or earlier
    define_method('log') { $log } unless method_defined?(:log)

    def configure(conf)
      super
    end

    def start
      super
    end

    def shutdown
      super
    end

    def emit(tag, es, chain)
      es.each do |time, record|
        t = tag.dup
        new_record = parse_cookie(record)

        t = @tag_prefix + t unless @tag_prefix.nil?

        router.emit(t, time, new_record)
      end
      chain.next
    rescue StandardError => e
      log.warn("out_parse_cookie: error_class:#{e.class} error_message:#{e.message} tag:#{tag} es:#{es} bactrace:#{e.backtrace.first}")
    end

    def parse_cookie(record)
      if record[key]
        parsed_cookie = CGI::Cookie.parse(record[key])
        hash = {}
        parsed_cookie.each do |k, array|
          hash.merge!(k => array.select { |v| v.class == String })
        end

        hash = hash.reject { |_k, v| v == [] } if remove_empty_array == true

        if single_value_to_string == true
          hash.each do |k, v|
            hash[k] = v[0] if v.count == 1
          end
        end

        target = sub_key ? (record[sub_key] ||= {}) : record

        target.merge!(hash)

        record.delete(key) if remove_cookie
      end
      record
    rescue StandardError => e
      log.warn("out_parse_cookie: error_class:#{e.class} error_message:#{e.message} tag:#{tag} record:#{record} bactrace:#{e.backtrace.first}")
    end
  end
end
