require "test_helper"

class PresentOptionsTest < Minitest::Spec
  class Create < Trailblazer::Activity::Railway
    step :model

    def model(ctx, **)
      ctx[:model] = Object.new
    end
  end

  let(:uninitialized_session) { Trailblazer::Pro::Session::Uninitialized.new(api_key: api_key, trailblazer_pro_host: trailblazer_pro_host) }

  it "with {render_wtf: true}" do
    ctx = {}

    signal, (ctx, _), _, output, (token, trace_id, debugger_url, trace_envelope) = Trailblazer::Developer.wtf?(
      Create,
      [ctx, {}],
      present_options: {render_method: Trailblazer::Pro::Debugger, session: uninitialized_session, render_wtf: true}, # FIXME:  why do we have to pass {:session} here?
    )

    assert_equal output, %(PresentOptionsTest::Create
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
      present_options: {render_method: Trailblazer::Pro::Debugger, session: uninitialized_session, render_wtf: false}, # FIXME:  why do we have to pass {:session} here?
    )

    assert_equal output, %([TRB PRO] view trace at https://ide.trailblazer.to/#{trace_id})
  end

  it "returned trace data is correct" do
    ctx = {}

    signal, (ctx, _), _, output, (token, trace_id, debugger_url, trace_envelope) = Trailblazer::Developer.wtf?(
      Create,
      [ctx, {}],
      present_options: {render_method: Trailblazer::Pro::Debugger, session: uninitialized_session},
    )

    assert_equal trace_id.size, 20
    assert_equal debugger_url, "https://ide.trailblazer.to/#{trace_id}"

    assert_equal trace_envelope[:fields].keys, [:activity_name, :trace, :created_at]
    assert_equal trace_envelope[:fields][:activity_name], {:stringValue=>PresentOptionsTest::Create}
    assert trace_envelope[:fields][:created_at][:timestampValue] < DateTime.now

    trace_data = JSON.parse(trace_envelope[:fields][:trace][:stringValue])
    trace_nodes = trace_data["nodes"]
    trace_variable_versions = trace_data["variable_versions"]

    model_1_id = trace_variable_versions["model"].keys[0]

    assert_equal model_1_id.class, String

  # Assert trace/nodes
    assert_equal trace_nodes.size, 4
    assert_equal trace_nodes[0].slice("level", "runtime_id", "label"), {"level"=>0, "runtime_id"=>nil, "label"=>"PresentOptionsTest::Create"}
    assert_equal trace_nodes[0]["ctx_snapshots"], {
      "before"=>[],
      "after" => [["model", {"version"=>model_1_id, "has_changed"=>false}]]}

    assert_equal trace_nodes[1].slice("level", "runtime_id", "label"), {"level"=>1, "runtime_id"=>"Start.default", "label"=>"Start.default"}
    assert_equal trace_nodes[1]["ctx_snapshots"], {
      "before"=>[],
      "after" => []}

    assert_equal trace_nodes[2].slice("level", "runtime_id", "label"), {"level"=>1, "runtime_id"=>"model", "label"=>"model"}
    assert_equal trace_nodes[2]["ctx_snapshots"], {
      "before"=>[],
      "after" => [["model", {"version"=>model_1_id, "has_changed"=>true}]]}

    assert_equal trace_nodes[3].slice("level", "runtime_id", "label"), {"level"=>1, "runtime_id"=>"End.success", "label"=>"End.success"}
    assert_equal trace_nodes[3]["ctx_snapshots"], {
      "before"=>[["model", {"version"=>model_1_id, "has_changed"=>false}]],
      "after" => [["model", {"version"=>model_1_id, "has_changed"=>false}]]}

    assert_equal [trace_nodes[0]["id"], trace_nodes[1]["id"], trace_nodes[2]["id"], trace_nodes[3]["id"]].uniq.size, 4

  # Assert trace/variable_versions
    assert_equal trace_variable_versions, {"model"=>{model_1_id => ctx[:model].to_s}}

  # Assert version
    assert_equal trace_data["pro_version"], Trailblazer::Pro::VERSION
  end
end
