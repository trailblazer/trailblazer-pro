$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "trailblazer/pro"

require "minitest/autorun"

Minitest::Spec.class_eval do
  def assert_equal(asserted, expected)
    super(expected, asserted)
  end

  let(:api_key) { "tpka_f5c698e2_d1ac_48fa_b59f_70e9ab100604" }
  # let(:trailblazer_pro_host) { "http://localhost:3000" }
  let(:trailblazer_pro_host) { "https://test-pro-rails-jwt.onrender.com" }

  after do
    Trailblazer::Pro::Session.session = nil
    Trailblazer::Pro::Session.wtf_present_options = nil
  end

  def assert_web_and_cli_trace(output, operation: Create)
    trace_id = output[-21..-2] # skip newline.

    assert_equal trace_id.size, 20

    assert_equal output, %(#{operation}
|-- \e[32mStart.default\e[0m
|-- \e[32mmodel\e[0m
`-- End.success
\e[1m[TRB PRO] view trace (#{operation}) at \e[22mhttps://ide.trailblazer.to/#{trace_id}
)
  end

  def assert_cli_trace(output, operation: Create)
    assert_equal output, %(#{operation}
|-- \e[32mStart.default\e[0m
|-- \e[32mmodel\e[0m
`-- End.success
)
  end
end

require "trailblazer/operation"

class Minitest::Spec::Create < Trailblazer::Operation
  step :model

  def model(ctx, **)
    ctx[:model] = Object.new
  end
end

require "trailblazer/developer" # FIXME.

