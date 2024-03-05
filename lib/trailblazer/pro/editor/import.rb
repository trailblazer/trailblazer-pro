module Trailblazer
  module Pro
    module Editor
      class Import < Trailblazer::Activity::Railway
        step Subprocess(Client::Connect), id: :connect
        step :retrieve_document
        step :store_document

        def retrieve_document(ctx, session:, diagram_slug:, **)
          id_token = session.id_token

          ctx[:response] = response = Faraday.get(
            "#{session.trailblazer_pro_host}/api/v1/diagrams/#{diagram_slug}/export",
            {},
            {'Content-Type'=>'application/json', "Accept": "application/json",
              "Authorization": "Bearer #{id_token}"
            }
          )

          return false unless response.status == 200 # TODO: abstract this for other users, and use "endpoint" paths.

          ctx[:pro_json_document] = ctx[:response].body
        end

        def store_document(ctx, pro_json_document:, target_filename:, **)
          File.write(target_filename, pro_json_document) > 0
        end
      end

    end # Editor
  end
end
