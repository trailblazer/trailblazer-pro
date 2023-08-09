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
  end

  it "{Operation.WTF?} overrides trace_guards and still traces!" do
    operation = Class.new(Create)
      .extend(Trailblazer::Pro::Operation::WTF)
      .extend(Trailblazer::Pro::Operation::Call) # this adds trace_guards.

    Trailblazer::Pro.initialize!(api_key: api_key, trailblazer_pro_host: trailblazer_pro_host)

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

  after do
    Trailblazer::Pro::Session.trace_guards = Trailblazer::Pro::Trace::Decision.new([]) # here we say "don't trace anything!"
  end
end

class ExtendedOperationCallTest < Minitest::Spec
  after do
    Trailblazer::Pro::Session.trace_guards = Trailblazer::Pro::Trace::Decision.new([]) # here we say "don't trace anything!"
  end

  it "per default, without custom {trace_guards} we don't trace even when {Operation::Call} is installed" do
    operation = Class.new(Create)
      .extend(Trailblazer::Pro::Operation::WTF)
      .extend(Trailblazer::Pro::Operation::Call) # this adds trace_guards.

    Trailblazer::Pro.initialize!(api_key: api_key, trailblazer_pro_host: trailblazer_pro_host)

    output, _ = capture_io do
      signal, _ = operation.(params: {}) # normal Operation.call()
      assert_equal signal.success?, true
    end

    # assert_cli_trace(output, operation: operation)
    assert_equal output, %()

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

  it "with trace_guards, we trace in {Operation.call()}" do
    operation = Class.new(Create)
      .extend(Trailblazer::Pro::Operation::WTF)
      .extend(Trailblazer::Pro::Operation::Call) # this adds trace_guards.

    Trailblazer::Pro.initialize!(api_key: api_key, trailblazer_pro_host: trailblazer_pro_host)
    Trailblazer::Pro::Session.trace_guards = Trailblazer::Pro::Trace::Decision.new([
      ->(activity, ctx) { activity == operation ? [Trailblazer::Pro::Trace::Wtf, {}] : false }
    ])

    output, _ = capture_io do
      signal, _ = operation.(params: {})
    end

    # We simply print the CLI trace.
    assert_web_and_cli_trace(output, operation: operation)

  # run another op without Operation::Call
    output, _ = capture_io do
      signal, _ = Create.(params: {})
      assert_equal signal.success?, true
    end

    assert_equal output, %()

  # run a non-registered OP that is not covered by trace_guards
    operation = Class.new(Create)
      .extend(Trailblazer::Pro::Operation::WTF)
      .extend(Trailblazer::Pro::Operation::Call)

      output, _ = capture_io do
      signal, _ = Create.(params: {})
      assert_equal signal.success?, true
    end

    assert_equal output, %()
  end

  it "with trace_guards DSL, we trace in {Operation.call()} for selected OPs" do
    create = Class.new(Create)
      .extend(Trailblazer::Pro::Operation::WTF)

    update = Class.new(Create)

    Trailblazer::Pro.initialize!(api_key: api_key, trailblazer_pro_host: trailblazer_pro_host)
    Trailblazer::Pro.trace_operations!(
      create => true,                             # [Trailblazer::Pro::Trace::Wtf, {}]
      update => Trailblazer::Developer::Wtf
    )

    output, _ = capture_io do
      signal, _ = create.(params: {})
    end

    # We simply print the CLI trace.
    assert_web_and_cli_trace(output, operation: create)

  # run another OP with a different strategy
    output, _ = capture_io do
      signal, _ = update.(params: {})
      assert_equal signal.success?, true
    end

    assert_cli_trace output, operation: update

  # run another op without Operation::Call
    output, _ = capture_io do
      signal, _ = Create.(params: {})
      assert_equal signal.success?, true
    end

    assert_equal output, %()
  end
end
