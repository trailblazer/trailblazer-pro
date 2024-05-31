module Trailblazer
  module Pro
    # Called in {Trace::Present.call} as {:render_method}.
    # This method always returns [output, *], where {output}
    # is an arbitrary string to be written to the logger or CLI.
    def self.invoke_debugger(**kws)
      _, (ctx, _) = Activity::TaskWrap.invoke(Debugger, [{now: DateTime.now, **kws, output: []}, {}])

      return ctx[:output], [ctx[:session], ctx[:id], ctx[:debugger_url], ctx[:data_to_store], ctx[:session_updated]]
    end

    # This is the {:render_method} implementation (for Trace::Present)
    # when using PRO's wtf.
    class Debugger < Trailblazer::Activity::Railway
      step :render_trace_data
      step :trace_envelope_for
      step Subprocess(Push)
      step :render_original_wtf_trace
      fail :render_original_wtf_trace, id: "fail.render_original_wtf_trace"
      fail :trace_with_appended_error_message
      step :render_debugger_link
      step :compile_output
      fail :compile_output, id: "fail.compile_output"

      def trace_with_appended_error_message(ctx, error_message:, output:, **)
        ctx[:output] << error_message
      end

      def render_trace_data(ctx, debugger_trace:, activity:, **)
        flat_tree_json = debugger_trace.to_a.collect do |debugger_node|

          # TODO: do we even need to grab tw by path here?
          introspect_nodes_node = OpenStruct.new(task: debugger_node.task)
          tw_render = Developer::Render::TaskWrap.render_for(debugger_node.activity, introspect_nodes_node)

          # This rendering code has deep knowledge of Trace/pro/v1 tracing interface.
          ctx[:trace_data] = {
            id:             debugger_node.id.to_s,
            runtime_id:     debugger_node.runtime_id,
            level:          debugger_node.level,
            label:          debugger_node.label,
            ctx_snapshots: {
              before: debugger_node.snapshot_before.data[:ctx_variable_changeset].collect { |name, hash, has_changed| [name, {version: hash.to_s, has_changed: !!has_changed}] },
              after:  debugger_node.snapshot_after ?
                debugger_node.snapshot_after.data[:ctx_variable_changeset].collect { |name, hash, has_changed| [name, {version: hash.to_s, has_changed: !!has_changed}] } # FIXME: of course, this is horrible.
                : [],
            },
            returned_signal: debugger_node.snapshot_after ? debugger_node.snapshot_after.data[:signal] : nil, # TODO: test an exception wtf? trace.

            rendered_task_wrap: tw_render,
          }
        end

        ctx[:trace_data] = JSON.dump(
          nodes:              flat_tree_json,
          variable_versions:  debugger_trace.to_h[:variable_versions].to_h,
          pro_version: Pro::VERSION.to_s,
        )
      end

      def trace_envelope_for(ctx, activity:, trace_data:, **)
        ctx[:data_to_store] = {
          fields: {
            activity_name:   {stringValue: activity},
            trace:  {stringValue: trace_data},
            created_at: {timestampValue: DateTime.now}, # we're using local client time currently.
          }
        }
      end

      def render_original_wtf_trace(ctx, render_wtf: false, debugger_trace:, renderer:, output:, color_map: Developer::Wtf::Renderer::DEFAULT_COLOR_MAP, **)
        return true unless render_wtf
        # TODO: take the color_map from outside caller.
        wtf_output = Developer::Trace::Present.render(debugger_trace: debugger_trace, renderer: renderer, color_map: Developer::Wtf::Renderer::DEFAULT_COLOR_MAP) # , activity: activity

        ctx[:output] << wtf_output
      end

      # :id is :stored_trace_id.
      def render_debugger_link(ctx, id:, activity:, **)
        debugger_url = "https://ide.trailblazer.to/#{id}"
        # output       = "[TRB PRO] view trace (#{activity}) at #{debugger_url}"
        # output       = Developer::Wtf::Renderer::String.bold(output)
        link = Developer::Wtf::Renderer::String.bold("[TRB PRO] view trace (#{activity}) at ")
        link += debugger_url # DISCUSS: what do we want bold here?

        ctx[:link] = link
        ctx[:debugger_url] = debugger_url

        ctx[:output] << link
      end

      def compile_output(ctx, output:, **)
        ctx[:output] = output.join("\n")
      end
    end # Debugger
  end
end
