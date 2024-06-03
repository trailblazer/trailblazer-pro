require "test_helper"

# Tests the public API.
require "trailblazer/operation"

class IntegrationTest < Minitest::Spec
  # Test when people don't use wtf? anymore but (Activity.call), only.
  # This is an end-to-end test, we can really only assert CLI output.
  it "web/cli trace settings" do
    Trailblazer::Pro.initialize!(api_key: api_key, trailblazer_pro_host: trailblazer_pro_host)

    Trailblazer::Operation.extend(Trailblazer::Pro::Operation::Call)
    Trailblazer::Activity.extend(Trailblazer::Pro::Call::Activity)

    Trailblazer::Pro::Session.trace_guards = Trailblazer::Pro::Trace::Decision.new(
      [
        ->(activity, *) { activity == Create ? [Trailblazer::Pro::Trace::Wtf, {render_wtf: true}] : false }, # false means "call super"
        ->(activity, ctx) { activity == Trailblazer::Pro::Debugger && ctx[:activity] == IntegrationTest::Create ? [Trailblazer::Developer::Wtf, {}] : false }, # false means "call super"
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

    assert_equal lines[0], "Trailblazer::Pro::Debugger"       # beginning of {Push} CLI trace

    trace_id = lines[-1][-20..-1]

    assert_equal trace_id.size, 20
    assert_equal lines[wtf_last_line_index + 1..-1].join("\n"),
%(Minitest::Spec::Create
|-- \e[32mStart.default\e[0m
|-- \e[32mmodel\e[0m
`-- End.success
\e[1m[TRB PRO] view trace (Minitest::Spec::Create) at \e[22mhttps://ide.trailblazer.to/#{trace_id}) # Create is on CLI and web.

    output, _ = capture_io do
      signal, (ctx, _) = ::Trailblazer::Activity.(untraced_activity, {params: {}}) # this run doesn't add any output/tracing
    end

    assert_equal output, ""
  end
end
