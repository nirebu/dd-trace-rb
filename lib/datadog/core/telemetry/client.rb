require_relative 'emitter'
require_relative 'heartbeat'
require_relative '../utils/forking'

module Datadog
  module Core
    module Telemetry
      # Telemetry entrypoint, coordinates sending telemetry events at various points in app lifecyle
      class Client
        attr_reader \
          :emitter,
          :enabled,
          :unsupported,
          :worker

        include Core::Utils::Forking

        # @param enabled [Boolean] Determines whether telemetry events should be sent to the API
        def initialize(enabled: true)
          @enabled = enabled
          @emitter = Emitter.new
          @stopped = false
          @unsupported = false
          @worker = Telemetry::Heartbeat.new(enabled: @enabled) do
            heartbeat!
          end
        end

        def disable!
          @enabled = false
          @worker.enabled = false
        end

        def started!
          return if !@enabled || forked?

          res = @emitter.request(:'app-started')

          if res.not_found? # Telemetry is only supported by agent versions 7.34 and up
            Datadog.logger.debug('Agent does not support telemetry; disabling future telemetry events.')
            disable!
            @unsupported = true # Prevent telemetry from getting re-enabled
          end

          res
        end

        def emit_closing!
          return if !@enabled || forked?

          @emitter.request(:'app-closing')
        end

        def stop!
          return if @stopped

          @worker.stop(true, 0)
          @stopped = true
        end

        def integrations_change!
          return if !@enabled || forked?

          @emitter.request(:'app-integrations-change')
        end

        private

        def heartbeat!
          return if !@enabled || forked?

          @emitter.request(:'app-heartbeat')
        end
      end
    end
  end
end
