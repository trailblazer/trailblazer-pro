module Trailblazer::Pro
  module Trace
    class Decision < Struct.new(:guards)
      def call(activity, ctx) # DISCUSS: signature not stable, yet.
        result  = nil
        options = {}

        guards.each do |guard|
          result = guard.(activity, ctx) and break # DISCUSS: {ctx.to_hash}?
        end

        if result
          options = Trailblazer::Pro::Trace::Wtf.options_for_canonical_invoke

          # DISCUSS: how could we "nest" steps? Here, we simply invoke trace, wtf and pro steps as if they were part of the options compiler.
          # NOTE: do not copy this, API still in state of flux.
          options = Trailblazer::Invoke::Options.new(Trailblazer::Activity::TaskWrap::Pipeline.new([])).(activity, {}, **options)
        end

        options
      end
    end
  end
end

