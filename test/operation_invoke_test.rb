require "test_helper"

class OperationTest < Minitest::Spec
  after do
    Trailblazer::Pro::Session.trace_guards = Trailblazer::Pro::Trace::Decision.new([]) # here we say "don't trace anything!"
  end

  it "without PRO configured, and without trace_guards, everything works as expected" do
    operation = Class.new(Create)

    output, _ = capture_io do
      signal, _ = operation.(params: {}, trace?: true)

      assert_equal signal.success?, true
    end

    assert_equal output, %()

    output, _ = capture_io do
      signal, _ = operation.wtf?(params: {}, trace?: true)
    end

    assert_cli_trace(output, operation: operation)
  end

  it "" do
    operation = Class.new(Create)

    Trailblazer::Pro.initialize!(api_key: api_key, trailblazer_pro_host: trailblazer_pro_host)

    Trailblazer::Pro::Session.trace_guards = Trailblazer::Pro::Trace::Decision.new([
      ->(operation, options) do
        options[:trace?]
      end
    ])

    #@ We want tracing via PRO.
    output, _ = capture_io do
      signal, _ = operation.(params: {}, trace?: true)

      assert_equal signal.success?, true
    end

    assert_web_and_cli_trace(output, operation: operation)

    #@ No tracing!
    output, _ = capture_io do
      signal, _ = operation.(params: {}, trace?: false)

      assert_equal signal.success?, true
    end

    assert_equal output, %()
  end

  it "{Operation.wtf?} will trace on CLI, only (unless {trace_guards} defined)" do
    operation = Class.new(Create)

    Trailblazer::Pro.initialize!(api_key: api_key, trailblazer_pro_host: trailblazer_pro_host)

    output, _ = capture_io do
      signal, _ = operation.wtf?(params: {})
    end

    # We simply print the CLI trace.
    assert_cli_trace(output, operation: operation)
  end


  it "with trace_guards DSL, we trace selected OPs" do
    create = Class.new(Create)
    update = Class.new(Create)

    Trailblazer::Pro.initialize!(api_key: api_key, trailblazer_pro_host: trailblazer_pro_host)
    Trailblazer::Pro.trace_operations!(create, update)

    output, _ = capture_io do
      signal, _ = create.(params: {})
    end

    # We simply print the CLI trace.
    assert_web_and_cli_trace(output, operation: create)

  # run another OP with tracing
    output, _ = capture_io do
      signal, _ = update.(params: {})
      assert_equal signal.success?, true
    end
    assert_web_and_cli_trace output, operation: update

  # run another op without tracing
    output, _ = capture_io do
      signal, _ = Create.(params: {})
      assert_equal signal.success?, true
    end

    assert_equal output, %()
  end

  it "(regression test) {Operation.call} doesn't send {:present_options}" do
    require 'webmock/minitest'
    WebMock.disable_net_connect!(allow: [trailblazer_pro_host, "identitytoolkit.googleapis.com"])

    firebase_store_request_body = nil # FIXME: use dependency injection via TRB to "expect" this request.
    stub_request(:any, /firestore/).with { |request| firebase_store_request_body = request.body ; true }.and_return(body: %({"name": "bla/blubb_id123123123123"}))

    operation = Class.new(Create)

    Trailblazer::Pro.initialize!(api_key: api_key, trailblazer_pro_host: trailblazer_pro_host)
    Trailblazer::Pro::Session.trace_guards = Trailblazer::Pro::Trace::Decision.new([
      ->(activity, ctx) { true }
    ])

    output, _ = capture_io do
      signal, _ = operation.(params: {})
    end

    # We simply print the CLI trace.
    assert_web_and_cli_trace(output, operation: operation)

    assert firebase_store_request_body !~ /present_options/

    WebMock.disable!
  end
end
