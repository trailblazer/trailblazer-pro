require_relative "pro/version"
require "trailblazer/activity/dsl/linear"
require "faraday"

module Trailblazer
  module Pro
    class Error < StandardError; end
    # Your code goes here...
  end
end

require_relative "pro/session"
require_relative "pro/session"
require_relative "pro/trace/signin"
require_relative "pro/trace/refresh"
require_relative "pro/trace/store"
require_relative "pro/trace/wtf"
require_relative "pro/debugger"

Trailblazer::Pro::Session.wtf_present_options = {
  present_options: {
    render_method: Trailblazer::Pro::Debugger,
    # token: nil,
    # api_key: api_key
  }
}
