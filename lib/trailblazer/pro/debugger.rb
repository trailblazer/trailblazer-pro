module Trailblazer
  module Pro
    module Debugger
      module_function

      def call(debugger_nodes, activity:, **options)
        trace_data = render_trace_data(debugger_nodes, activity: activity, **options)

        trace_envelope = {
          name:   activity,
          trace:  trace_data,
          created_at: {".sv" => "timestamp"}, # https://firebase.google.com/docs/reference/rest/database#section-server-values
        }

        # FIXME: remove
        File.write("PRO-TRACE-#{Time.now}.json", JSON.pretty_generate(JSON.parse(trace_data)))

        token, stored_trace_id = push(trace_envelope.to_json, activity: activity, **options)

        debugger_url = "https://ide.trailblazer.to/#{stored_trace_id}"
        output       = "[TRB PRO] view trace at #{debugger_url}"

        returned_values = [token, stored_trace_id, debugger_url]

        return output, returned_values
      end

      def render_trace_data(debugger_nodes, activity:, **)
        # Developer::Trace::Present.render(debugger_nodes)
        top_level_activity = activity
        # top_level_activity = debugger_nodes[0].captured_input.task # TODO: pass explicitely.

        flat_tree_json = debugger_nodes.collect do |n|
          task      = n.task
          node, activity, _ = Developer::Introspect.find_path(top_level_activity, n[:compile_path]) # DISCUSS: we don't need that here.

# TODO: do we even need to grab tw by path here?
          tw_render = Developer::Render::TaskWrap.render_for(activity, node)


          {
            level: n.level,
            id: n.runtime_id,
            path: n.compile_path,
            runtime_path: n.runtime_path,
            label: n.label,
            input_ctx: n.captured_input.data[:ctx_snapshot],
            output_ctx: n.captured_output.data[:ctx_snapshot],

            rendered_task_wrap: tw_render,
          }
        end

        JSON.dump(flat_tree_json)
      end

      def push(trace_json, activity:, token:, api_key:, **options)
        # require "json"
        # html = File.open("/home/nick/projects/ide/public/data.json", "w")
        # html.write(JSON.dump(flat_tree_json))

        # Signin first time
        if token.nil?
          signal, (ctx, _) = Trailblazer::Developer.wtf?(Trailblazer::Pro::Trace::Signin, [{api_key: api_key, **options}, {}])

          raise unless signal.to_h[:semantic] == :success

          id_token            = ctx[:model]
          firebase_upload_url = ctx[:firebase_upload_url]

          token = [id_token, firebase_upload_url]
        end

        id_token, firebase_upload_url = token

        if id_token.valid?
          # raise token[1].inspect
          signal, (ctx, flow_options) = Trailblazer::Developer.wtf?(Trailblazer::Pro::Trace::Store, [{firebase_upload_url: token[1], data_to_store: trace_json}, {}])

          stored_trace_id = ctx[:id]
        else
          raise "apply refresh__token, not implemented yet"
        end

        return token, stored_trace_id
      end

      def bla_2BRM

require "cgi"

        tw_html = %{}

        ctx_html = %{}

        tree_html = %{
<style>
  table, th, td {
    border: 1px solid black;
  }
</style>
          <table>}

        flat_tree_json.each do |node|
          indent_tds = node[:level].times.collect { |i| "<td></td>" }.join("")
          tree_html << %{<tr>
#{indent_tds}
  <td>
    <a href="##{tw_anchor = node[:path].collect { |segment| CGI::escapeHTML(segment.to_s) }.join("@")}">
      #{CGI::escapeHTML(node[:label].to_s)}
    </a>
  </td>
</tr>}


          # task_node = Introspect.find_path(top_level_activity, node[:path])

          tw_html << %{
            <a name="#{tw_anchor}" />
            <h2>
              #{node[:runtime_path]}
            </h2>
            <pre>
              #{CGI::escapeHTML(node[:rendered_task_wrap])}
            </pre>
          }

          ctx_render = %{
            <table>}

          node[:input_ctx].collect do |k, v|
            ctx_render << %{<tr><td>#{k}</td><td>#{CGI::escapeHTML(v.to_s)}</td></tr>}
          end

          ctx_render << %{  </table>
          }

          out_render = %{
            <table>}

          [node[:output_ctx]||[]].collect do |k, v|
            out_render << %{<tr><td>#{k}</td><td>#{CGI::escapeHTML(v.to_s)}</td></tr>}
          end

          out_render << %{  </table>
          }



          tw_html << %{
            <h3>Ctx/in</h3>

            #{ctx_render}

            <h3>Ctx/out</h3>
            #{out_render}
          }
        end

        tree_html << "</table>"




        html = File.open("/home/nick/projects/trailblazer-pro/pro.html", "w")
        html.write(tree_html + tw_html )
      end
    end
  end
end
