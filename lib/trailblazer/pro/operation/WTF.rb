module Trailblazer
  module Pro
    module Operation
      module WTF
        # {Operation.WTF?} will always use web tracing and CLI.
        def WTF?(options)
          call_with_public_interface(
            options, 
            {}, 
            invoke_class:     Trailblazer::Pro::Trace::Wtf, 
            present_options: {render_wtf: true}
          )
        end
      end
    end # Operation
  end
end
