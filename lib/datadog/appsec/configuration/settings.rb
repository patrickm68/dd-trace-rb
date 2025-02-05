# typed: false

module Datadog
  module AppSec
    module Configuration
      # Configuration settings, acting as an integration registry
      # TODO: as with Configuration, this is a trivial implementation
      class Settings
        class << self
          def boolean
            lambda do |v|
              case v
              when /(1|true)/i
                true
              when /(0|false)/i, nil
                false
              else
                raise ArgumentError, "invalid boolean: #{v.inspect}"
              end
            end
          end

          # TODO: allow symbols
          def string
            ->(v) { v.to_s }
          end

          def integer
            lambda do |v|
              case v
              when /(\d+)/
                Integer(Regexp.last_match[1])
              else
                raise ArgumentError, "invalid integer: #{v.inspect}"
              end
            end
          end

          # rubocop:disable Metrics/MethodLength
          def duration(base = :ns, type = :integer)
            lambda do |v|
              cast = case type
                     when :integer, Integer
                       method(:Integer)
                     when :float, Float
                       method(:Float)
                     else
                       raise ArgumentError, "invalid type: #{v.inspect}"
                     end

              scale = case base
                      when :s
                        1_000_000_000
                      when :ms
                        1_000_000
                      when :us
                        1000
                      when :ns
                        1
                      else
                        raise ArgumentError, "invalid base: #{v.inspect}"
                      end

              case v
              when /^(\d+)h$/
                cast.call(Regexp.last_match[1]) * 1_000_000_000 * 60 * 60 / scale
              when /^(\d+)m$/
                cast.call(Regexp.last_match[1]) * 1_000_000_000 * 60 / scale
              when /^(\d+)s$/
                cast.call(Regexp.last_match[1]) * 1_000_000_000 / scale
              when /^(\d+)ms$/
                cast.call(Regexp.last_match[1]) * 1_000_000 / scale
              when /^(\d+)us$/
                cast.call(Regexp.last_match[1]) * 1_000 / scale
              when /^(\d+)ns$/
                cast.call(Regexp.last_match[1]) / scale
              when /^(\d+)$/
                cast.call(Regexp.last_match[1])
              else
                raise ArgumentError, "invalid duration: #{v.inspect}"
              end
            end
          end
          # rubocop:enable Metrics/MethodLength
        end

        DEFAULTS = {
          enabled: false,
          ruleset: :recommended,
          waf_timeout: 5_000, # us
          waf_debug: false,
          trace_rate_limit: 100, # traces/s
        }.freeze

        ENVS = {
          'DD_APPSEC_ENABLED' => [:enabled, Settings.boolean],
          'DD_APPSEC_RULES' => [:ruleset, Settings.string],
          'DD_APPSEC_WAF_TIMEOUT' => [:waf_timeout, Settings.duration(:us)],
          'DD_APPSEC_WAF_DEBUG' => [:waf_debug, Settings.boolean],
          'DD_APPSEC_TRACE_RATE_LIMIT' => [:trace_rate_limit, Settings.integer],
        }.freeze

        Integration = Struct.new(:integration, :options)

        def initialize
          @integrations = []
          @options = DEFAULTS.dup.tap do |options|
            ENVS.each do |env, (key, conv)|
              options[key] = conv.call(ENV[env]) if ENV[env]
            end
          end
        end

        def enabled
          @options[:enabled]
        end

        def ruleset
          @options[:ruleset]
        end

        def waf_timeout
          @options[:waf_timeout]
        end

        def waf_debug
          @options[:waf_debug]
        end

        def trace_rate_limit
          @options[:trace_rate_limit]
        end

        def [](integration_name)
          integration = Datadog::AppSec::Contrib::Integration.registry[integration_name]

          raise ArgumentError, "'#{integration_name}' is not a valid integration." unless integration

          integration.options if integration
        end

        def merge(dsl)
          dsl.options.each do |k, v|
            @options[k] = v unless v.nil?
          end

          return self unless @options[:enabled]

          # patcher.patch may call configure again, hence merge might be called again so it needs to be reentrant
          dsl.instruments.each do |instrument|
            # TODO: error handling
            registered_integration = Datadog::AppSec::Contrib::Integration.registry[instrument.name]
            @integrations << Integration.new(registered_integration, instrument.options)

            # TODO: move to a separate apply step
            klass = registered_integration.klass
            if klass.loaded? && klass.compatible?
              instance = klass.new
              instance.patcher.patch
            end
          end

          self
        end

        private

        # Restore to original state, for testing only.
        def reset!
          initialize
        end
      end
    end
  end
end
