module Trailblazer
  module Pro
    module Operation
      module WTF
        # {Operation.WTF?} will always use web tracing and CLI.
        def WTF?(options)
          invoke_with_public_interface(
            options,
            **Pro::Trace::Wtf.options_for_canonical_invoke
          )
        end
      end
    end # Operation
  end
end
