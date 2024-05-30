module Trailblazer
  module Pro
    module Debugger
      module_function

      # Called in {Trace::Present.call} as {:render_method}.
      # This method always returns [output, *], where {output}
      # is an arbitrary string to be written to the logger or CLI.
      def call(activity:, render_wtf: false, **options)
        output = ""

        trace_data      = render_trace_data(activity: activity, **options)
        trace_envelope  = trace_envelope_for(activity: activity, trace_data: trace_data)

        session, stored_trace_id, session_updated = push(trace_envelope, activity: activity, **options)

        if render_wtf
          output += render_original_wtf_trace(**options)
        end

        # This block covers when something in {push} above went wrong.
        if session.nil?
          output += stored_trace_id
          return output, []
        end

        debugger_link, debugger_url = render_debugger_link(stored_trace_id: stored_trace_id, activity: activity)

        output += debugger_link

        returned_values = [session, stored_trace_id, debugger_url, trace_envelope, session_updated]

        return output, returned_values
      end

      def render_trace_data(debugger_trace:, activity:, **)
        flat_tree_json = debugger_trace.to_a.collect do |debugger_node|

          # TODO: do we even need to grab tw by path here?
          introspect_nodes_node = OpenStruct.new(task: debugger_node.task)
          tw_render = Developer::Render::TaskWrap.render_for(debugger_node.activity, introspect_nodes_node)

          # This rendering code has deep knowledge of Trace/pro/v1 tracing interface.
          {
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

        JSON.dump(
          nodes:              flat_tree_json,
          variable_versions:  debugger_trace.to_h[:variable_versions].to_h,
          pro_version: Pro::VERSION.to_s,
        )
      end

      def trace_envelope_for(activity:, trace_data:)
        {
          fields: {
            activity_name:   {stringValue: activity},
            trace:  {stringValue: trace_data},
            created_at: {timestampValue: DateTime.now}, # we're using local client time currently.
          }
        }
      end

      def render_original_wtf_trace(debugger_trace:, renderer:, color_map: Developer::Wtf::Renderer::DEFAULT_COLOR_MAP, **)
        # TODO: take the color_map from outside caller.
        wtf_output = Developer::Trace::Present.render(debugger_trace: debugger_trace, renderer: renderer, color_map: Developer::Wtf::Renderer::DEFAULT_COLOR_MAP) # , activity: activity

        output = [wtf_output, output].join("\n")
      end

      def render_debugger_link(stored_trace_id:, activity:)
        debugger_url = "https://ide.trailblazer.to/#{stored_trace_id}"
        # output       = "[TRB PRO] view trace (#{activity}) at #{debugger_url}"
        # output       = Developer::Wtf::Renderer::String.bold(output)
        link = Developer::Wtf::Renderer::String.bold("[TRB PRO] view trace (#{activity}) at ")
        link += debugger_url # DISCUSS: what do we want bold here?

        return link, debugger_url
      end

      # DISCUSS: who defaults {:now}?
      def push(trace_data, activity:, now: DateTime.now, **options)
        # signal, (ctx, _) = Trailblazer::Developer.wtf?(Push, [{now: now, data_to_store: trace_data, **options}, {}])
        signal, (ctx, _) = Trailblazer::Activity.(Push, {now: now, data_to_store: trace_data, **options})
        # signal, (ctx, _) = Push.invoke([{now: now, data_to_store: trace_data, **options}, {}])

        session         = ctx[:session]
        stored_trace_id = ctx[:id]
        session_updated = ctx[:session_updated]

        return [nil, ctx[:error_message]] if signal.to_h[:semantic] == :failure # TODO: what to return?

        return session, stored_trace_id, session_updated
      end
    end # Debugger
  end
end
