module Trailblazer::Pro
  module Trace
    # Used in Activity.call monkey-patch.
    class Decision < Struct.new(:guards)
      def call(activity, ctx) # DISCUSS: signature not stable, yet.
        guards.each do |guard|
          result = guard.(activity, ctx) and return result # DISCUSS: {ctx.to_hash}?
        end

        false
      end
    end
  end
end

