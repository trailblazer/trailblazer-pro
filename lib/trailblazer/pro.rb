require_relative "pro/version"
# require "trailblazer/activity/dsl/linear"
require "trailblazer/invoke"
require "trailblazer/developer"
require "faraday"
require "ostruct"

module Trailblazer
  module Pro
    # Your code goes here...
  end
end

require_relative "pro/trace/decision"
require_relative "pro/session"
require_relative "pro/client/signin"
require_relative "pro/client/refresh"
require_relative "pro/client"
require_relative "pro/trace/store"
require_relative "pro/trace/wtf"
require_relative "pro/debugger/push"
require_relative "pro/debugger"
require_relative "pro/operation/WTF"


module Trailblazer
  module Pro
    module Invoke
      module Options
        def self.trace_guards_step_for_options_compiler(activity, options, **kws)
          # return {} # FIXME

          # raise kws.inspect
          _pro_options_for_invoke = Pro::Session.trace_guards.(activity, options)
        end
      end

    end
  end
end
# FIXME: what if OP isn't here?

# FIXME: order? we need to set this before OP is run
steps = Trailblazer::Invoke::Options.singleton_class.instance_variable_get(:@steps)

my_options_step = Trailblazer::Pro::Invoke::Options.method(:trace_guards_step_for_options_compiler)
my_options_step = Trailblazer::Invoke::Options::HeuristicMerge.build(my_options_step)

steps = steps + [Trailblazer::Activity::TaskWrap::Pipeline.Row("pro.trace_guards", my_options_step)]
Trailblazer::Invoke::Options.singleton_class.instance_variable_set(:@steps, steps)
