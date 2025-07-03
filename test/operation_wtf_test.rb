require "test_helper"

class OperationWTFTest < Minitest::Spec
  it "{Operation.WTF?} not configured" do
    operation = Class.new(Create)
      .extend(Trailblazer::Pro::Operation::WTF) # FIXME: do this automatically?

    exception = assert_raises do
      signal, _ = operation.WTF?(params: {})
    end

    # No PRO configured
    assert_equal exception.message, %([Trailblazer] Please configure your PRO API key.)
  end

  it "{Operation.WTF?} PRO configured, let's trace (web and CLI)!" do
    operation = Class.new(Create)
      .extend(Trailblazer::Pro::Operation::WTF)

    Trailblazer::Pro.initialize!(api_key: api_key, trailblazer_pro_host: trailblazer_pro_host)

    output, _ = capture_io do
      signal, _ = operation.WTF?(params: {})
    end

    assert_web_and_cli_trace(output, operation: operation)
  end

  it "{Operation.WTF?} overrides trace_guards and still traces!" do
    operation = Class.new(Create)
      .extend(Trailblazer::Pro::Operation::WTF)

    Trailblazer::Pro::Session.trace_guards = Trailblazer::Pro::Trace::Decision.new([
      ->(operation, options) { false }
    ])

    Trailblazer::Pro.initialize!(api_key: api_key, trailblazer_pro_host: trailblazer_pro_host)

    output, _ = capture_io do
      signal, _ = operation.WTF?(params: {})
    end

    assert_web_and_cli_trace(output, operation: operation)

    # FIXME: when a trace_guard is found, this will override WTF?.
  end
end
