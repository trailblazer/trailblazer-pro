module Trailblazer::Pro
  module Trace
    # cache the token for successive runs of {#wtf?}.
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

