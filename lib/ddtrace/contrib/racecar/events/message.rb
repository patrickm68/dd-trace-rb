# typed: false
require 'ddtrace/contrib/racecar/ext'
require 'ddtrace/contrib/racecar/event'

module Datadog
  module Contrib
    module Racecar
      module Events
        # Defines instrumentation for process_message.racecar event
        module Message
          include Racecar::Event

          EVENT_NAME = 'process_message.racecar'.freeze

          module_function

          def event_name
            self::EVENT_NAME
          end

          def span_name
            Ext::SPAN_MESSAGE
          end

          def span_options
            super.merge(tags: { Datadog::Ext::Metadata::TAG_OPERATION => Ext::TAG_OPERATION_MESSAGE })
          end
        end
      end
    end
  end
end
