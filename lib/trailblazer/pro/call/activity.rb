module Trailblazer
  module Pro
    module Call
      module Activity
        # This is the monkey-patch for {Activity.call}.
        # Here we decide whether to use tracing, and what to render,
        # or if we should bypass tracing.
        def call(activity, ctx)
          trace_strategy, present_options_merge = Pro::Session.trace_guards.(activity, ctx)

          if trace_strategy
            return trace_strategy.invoke(activity, [ctx, {}], present_options: present_options_merge)
          else
            return super
          end
        end
      end # Activity
    end
  end
end
