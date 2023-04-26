require_relative "pro/version"
require "trailblazer/activity/dsl/linear"
require "faraday"

module Trailblazer
  module Pro
    class Error < StandardError; end
    # Your code goes here...
  end
end

require_relative "pro/trace/signin"
