require "test_helper"

# Tests the public API.
require "trailblazer/operation"

class OperationCallTest < Minitest::Spec
  class Create < Trailblazer::Operation
    step :model

    def model(ctx, **)
      ctx[:model] = Object.new
    end
  end

  # Always run web tracing.
  it "Operation.WTF?" do
    Trailblazer::Pro.initialize!(api_key: api_key, trailblazer_pro_host: trailblazer_pro_host)

    # FIXME: monkey-patch world-wide
    Trailblazer::Operation.extend(Trailblazer::Pro::Operation::WTF)

    output, _ = capture_io do
      signal, (ctx, _) = Create.WTF?({params: {}})
    end

    trace_id = output[-21..-1]

    assert_equal output, %(OperationCallTest::Create
|-- \e[32mStart.default\e[0m
|-- \e[32mmodel\e[0m
`-- End.success
\e[1m[TRB PRO] view trace (OperationCallTest::Create) at \e[22mhttps://ide.trailblazer.to/#{trace_id}) # Create is on CLI and web.

    # also test if monkey-patched Operation still traces, even with settings saying no.
  end

  # Test when people don't use wtf? anymore but (Activity.call), only.
  # This is an end-to-end test, we can really only assert CLI output.
  it "web/cli trace settings" do
    Trailblazer::Pro.initialize!(api_key: api_key, trailblazer_pro_host: trailblazer_pro_host)

    Trailblazer::Operation.extend(Trailblazer::Pro::Operation::Call)
    Trailblazer::Activity.extend(Trailblazer::Pro::Call::Activity)

    Trailblazer::Pro::Session.trace_guards = Trailblazer::Pro::Trace::Decision.new(
      [
        ->(activity, *) { activity == OperationCallTest::Create ? [Trailblazer::Pro::Trace::Wtf, {render_wtf: true}] : false }, # false means "call super"
        ->(activity, ctx) { activity == Trailblazer::Pro::Debugger::Push && ctx[:data_to_store][:fields][:activity_name][:stringValue] == OperationCallTest::Create ? [Trailblazer::Developer::Wtf, {}] : false }, # false means "call super"
      ]
    )

    untraced_activity = Trailblazer::Activity::Railway()

    # Run activity with monkey-patched {Activity.call}.
    output, _ = capture_io do
      signal, (ctx, _) = Create.({params: {}})
    end

    # 1. Push is traced on CLI
    # 2. Create is CLI and web.

    lines = output.split("\n")
    cli_wtf_last_line = lines.find { |line| line == "`-- End.success" }
    wtf_last_line_index = lines.index(cli_wtf_last_line)

    assert_equal lines[0], "Trailblazer::Pro::Debugger::Push"       # beginning of {Push} CLI trace

    trace_id = lines[-1][-20..-1]

    assert_equal trace_id.size, 20
    assert_equal lines[wtf_last_line_index + 1..-1].join("\n"),
%(OperationCallTest::Create
|-- \e[32mStart.default\e[0m
|-- \e[32mmodel\e[0m
`-- End.success
\e[1m[TRB PRO] view trace (OperationCallTest::Create) at \e[22mhttps://ide.trailblazer.to/#{trace_id}) # Create is on CLI and web.

    output, _ = capture_io do
      signal, (ctx, _) = ::Trailblazer::Activity.(untraced_activity, {params: {}}) # this run doesn't add any output/tracing
    end

    assert_equal output, ""
  end
end
