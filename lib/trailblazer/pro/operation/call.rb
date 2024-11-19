module Trailblazer
  module Pro
    module Operation
      # @private This is experimental.
      module Call
        # This is the monkey-patch for {Operation.call}.
        # Here we decide whether to use tracing, and what to render,
        # or if we should bypass tracing.
        def call_with_public_interface(options, flow_options, **circuit_options)
          trace_strategy, present_options_merge = Pro::Session.trace_guards.(self, options)

          if trace_strategy
              # local invoke_class is overridden by circuit_options
            super(options, flow_options, invoke_class: trace_strategy, **circuit_options, present_options: present_options_merge)
          else
            super
          end
        end
      end
    end # Operation
  end
end
