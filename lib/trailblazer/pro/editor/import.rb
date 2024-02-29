module Trailblazer
  module Pro
    module Editor
      class Import < Trailblazer::Activity::Railway
        step Subprocess(Client::Connect), id: :connect
        step :retrieve_document
        step :store_document

        def retrieve_document(ctx, session:, diagram_slug:, **)
          id_token = session.id_token

          ctx[:response] = Faraday.get(
            "#{session.trailblazer_pro_host}/api/v2/diagrams/#{diagram_slug}/export",
            # "",
            {},
            {'Content-Type'=>'application/json', "Accept": "application/json",
              "Authorization": "Bearer #{id_token}"
            }
          )

          ctx[:pro_json_document] = ctx[:response].body
        end

        def store_document(ctx, pro_json_document:, target_filename:, **)
          # parsed_json = JSON.parse(pro_json_document) # DISCUSS: separate step?

          File.write(target_filename, pro_json_document)
        end
      end

    end # Editor
  end
end
