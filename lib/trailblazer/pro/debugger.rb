module Trailblazer
  module Pro
    module Debugger
      module_function

      # Called in {Trace::Present.call}.
      def call(debugger_trace:, activity:, **options)
        trace_data = render_trace_data(debugger_trace, activity: activity, **options)

        trace_envelope = {
          fields: {
            activity_name:   {stringValue: activity},
            trace:  {stringValue: trace_data},
            created_at: {timestampValue: DateTime.now}, # we're using local client time currently.
          }
        }

        # FIXME: remove
        # File.write("PRO-TRACE-#{Time.now}.json", JSON.pretty_generate(JSON.parse(trace_data)))

        token, stored_trace_id = push(trace_envelope, activity: activity, **options)

        debugger_url = "https://ide.trailblazer.to/#{stored_trace_id}"
        output       = "[TRB PRO] view trace at #{debugger_url}"

        returned_values = [token, stored_trace_id, debugger_url, trace_envelope]

        return output, returned_values
      end

      def render_trace_data(debugger_trace, activity:, **)
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

            rendered_task_wrap: tw_render,
          }
        end

        JSON.dump(
          nodes:              flat_tree_json,
          variable_versions:  debugger_trace.to_h[:variable_versions].to_h,
          pro_version: Pro::VERSION.to_s,
        )
      end

      def push(trace_data, activity:, token:, api_key:, **options)
        # require "json"
        # html = File.open("/home/nick/projects/ide/public/data.json", "w")
        # html.write(JSON.dump(flat_tree_json))

        # Signin first time
        if token.nil? # FIXME
          signal, (ctx, _) = Trailblazer::Developer.wtf?(Trailblazer::Pro::Trace::Signin, [{api_key: api_key, **options}, {}])

          raise unless signal.to_h[:semantic] == :success

          token                     = ctx[:model]
          id_token                  = ctx[:id_token]
          firebase_upload_url       = ctx[:firebase_upload_url]
          firestore_fields_template = ctx[:firestore_upload_template]

          # token = [id_token, firebase_upload_url]
        end

        # id_token, firebase_upload_url = token

        if token.valid?
          _signal, (ctx, _flow_options) = Trailblazer::Developer.wtf?(Trailblazer::Pro::Trace::Store, [{
            id_token:                   id_token,
            firebase_upload_url:        firebase_upload_url,
            firestore_fields_template:  firestore_fields_template,
            data_to_store:              trace_data
          }, {}]
          )

          stored_trace_id = ctx[:id]
        else
          raise "apply refresh__token, not implemented yet"
        end

        return token, stored_trace_id
      end

    end # Debugger
  end
end
