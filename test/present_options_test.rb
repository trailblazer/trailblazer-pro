require "test_helper"

class PresentOptionsTest < Minitest::Spec
  class Create < Trailblazer::Activity::Railway
    step :model

    def model(ctx, **)
      ctx[:model] = Object.new
    end
  end

  it "with {render_wtf: true}" do
    ctx = {}

    signal, (ctx, _), _, output, (token, trace_id, debugger_url, trace_envelope) = Trailblazer::Developer.wtf?(
      Create,
      [ctx, {}],
      present_options: {render_method: Trailblazer::Pro::Debugger, api_key: api_key, trailblazer_pro_host: trailblazer_pro_host, render_wtf: true}, # FIXME:  why do we have to pass {:session} here?
    )

    assert_equal output, %(ClientTest::Create
|-- \e[32mStart.default\e[0m
|-- \e[32mmodel\e[0m
`-- End.success
[TRB PRO] view trace at https://ide.trailblazer.to/#{trace_id})
  end

  it "with {render_wtf: false}" do
    ctx = {}

    signal, (ctx, _), _, output, (token, trace_id, debugger_url, trace_envelope) = Trailblazer::Developer.wtf?(
      Create,
      [ctx, {}],
      present_options: {render_method: Trailblazer::Pro::Debugger, api_key: api_key, session: nil, trailblazer_pro_host: trailblazer_pro_host, render_wtf: false}, # FIXME:  why do we have to pass {:session} here?
    )

    assert_equal output, %([TRB PRO] view trace at https://ide.trailblazer.to/#{trace_id})
  end
end
