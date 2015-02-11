module Fluent
  class ParseCookieOutput < Output
  	Fluent::Plugin.register_output('parse_cookie', self)
  	config_param :key,                    :string
    config_param :tag_prefix,             :string, :default => 'parsed_cookie.'
    config_param :remove_empty_array,     :bool, :default => false
    config_param :single_value_to_string, :bool, :default => false
    config_param :remove_cookie,          :bool, :default => false

    def initialize
      super
      require 'CGI'
    end

	  # Define `log` method for v0.10.42 or earlier
    unless method_defined?(:log)
      define_method("log") { $log }
    end

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
      es.each {|time, record|
        t = tag.dup
        new_record = parse_cookie(record)

        t = @tag_prefix + t unless @tag_prefix.nil?

        Engine.emit(t, time, new_record)
      }
      chain.next
    rescue => e
      log.warn("out_parse_cookie: error_class:#{e.class} error_message:#{e.message} tag:#{tag} es:#{es} bactrace:#{e.backtrace.first}")
    end

    def parse_cookie(record)
      if record[key]
        parsed_cookie = CGI::Cookie.parse(record[key])
        hash = {}
        parsed_cookie.each do |k,array| 
          hash.merge!({k => array.select {|v| v.class == String }})
        end
        
        hash = hash.select {|k, v| v != []} if remove_empty_array == true

        if single_value_to_string == true
          hash.each do |k, v|
            if v.count == 1
              hash[k] = v[0]
            end
          end
        end
        record.merge!(hash)
        record.delete(key) if remove_cookie
      end
      return record
    rescue => e
      log.warn("out_parse_cookie: error_class:#{e.class} error_message:#{e.message} tag:#{tag} record:#{record} bactrace:#{e.backtrace.first}")
    end
  end
end