require "test_helper"

# NO monkey-patching applied.
class NoExtendOperationTest < Minitest::Spec
  it "Operation.() runs op, no tracing" do
    signal= nil

    output, _ = capture_io do
      signal, _ = Create.(params: {})
    end

    assert_equal output, %()
    # assert_equal signal.to_h[:semantic], :success
    assert_equal signal.success?, true
  end

  it "{Operation.wtf?} prints to CLI, only" do
    signal= nil

    output, _ = capture_io do
      signal, _ = Create.wtf?(params: {})
    end

    assert_cli_trace output, operation: Create

    # assert_equal signal.to_h[:semantic], :success
    assert_equal signal.success?, true
  end

  it "{Operation.WTF?} doesn't exist" do
    exception = assert_raises do
      signal, _ = Create.WTF?(params: {})
    end

    # WTF? not installed
    assert_equal exception.message, %(undefined method `WTF?' for Minitest::Spec::Create:Class)
  end

  it "{Operation.WTF?} not configured" do
    operation = Class.new(Create)
      .extend(Trailblazer::Pro::Operation::WTF)

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

    # Trailblazer::Pro::Session.trace_guards = Trailblazer::Pro::Trace::Decision.new([])
  end

  it "{Operation.WTF?} overrides trace_guards and still traces!" do
    operation = Class.new(Create)
      .extend(Trailblazer::Pro::Operation::WTF)
      .extend(Trailblazer::Pro::Operation::Call) # this adds trace_guards.

    Trailblazer::Pro.initialize!(api_key: api_key, trailblazer_pro_host: trailblazer_pro_host)
    Trailblazer::Pro::Session.trace_guards = Trailblazer::Pro::Trace::Decision.new([]) # here we say "don't trace anything!"

    output, _ = capture_io do
      signal, _ = operation.WTF?(params: {})
    end

    assert_web_and_cli_trace(output, operation: operation)

    # FIXME: when a trace_guard is found, this will override WTF?.
  end

  # also test that you can use an ENV or config setting to activate CLI tracing without using PRO
  it "CLI trace set globally works even without PRO being configured" do
    operation = Class.new(Create)
      .extend(Trailblazer::Pro::Operation::WTF)
      .extend(Trailblazer::Pro::Operation::Call) # this adds trace_guards.

    # Trailblazer::Pro.initialize!(api_key: api_key, trailblazer_pro_host: trailblazer_pro_host)
    Trailblazer::Pro::Session.trace_guards = Trailblazer::Pro::Trace::Decision.new([
      ->(activity, *) { [Trailblazer::Developer::Wtf, {}] }
    ])

    output, _ = capture_io do
      signal, _ = operation.(params: {}) # normal Operation.call()
    end

    # We simply print the CLI trace.
    assert_cli_trace(output, operation: operation)
  end
end

class ExtendedOperationCallTest < Minitest::Spec
  it "no trace_guards configured, but everything else installed will trace on both CLI and web" do
    operation = Class.new(Create)
      .extend(Trailblazer::Pro::Operation::WTF)
      .extend(Trailblazer::Pro::Operation::Call) # this adds trace_guards.

    Trailblazer::Pro.initialize!(api_key: api_key, trailblazer_pro_host: trailblazer_pro_host)

    output, _ = capture_io do
      signal, _ = operation.(params: {}) # normal Operation.call()
    end

    assert_web_and_cli_trace(output, operation: operation)
  end

  it "extended Operation and {wtf?} will trace on CLI, only (unless {trace_guards} defined)" do
    operation = Class.new(Create)
      .extend(Trailblazer::Pro::Operation::WTF)
      .extend(Trailblazer::Pro::Operation::Call) # this adds trace_guards.

    Trailblazer::Pro.initialize!(api_key: api_key, trailblazer_pro_host: trailblazer_pro_host)

    output, _ = capture_io do
      signal, _ = operation.wtf?(params: {})
    end

    # We simply print the CLI trace.
    assert_cli_trace(output, operation: operation)
  end
end
