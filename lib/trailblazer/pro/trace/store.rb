module Trailblazer::Pro
  module Trace
    class Store < Trailblazer::Activity::Railway
      step :upload
      step :extract_id
      fail :error

      def upload(ctx, firebase_upload_url:, data_to_store:, id_token:, firestore_fields_template:, **)
        fields = data_to_store[:fields].merge(firestore_fields_template)

        json_to_store = data_to_store.merge(fields: fields).to_json

        ctx[:response] = Faraday.post(
          firebase_upload_url,
          json_to_store,
          {'Content-Type'=>'application/json', "Accept": "application/json",
            "Authorization": "Bearer #{id_token}"
          }
        )

        ctx[:response].status == 200
      end

      def extract_id(ctx, response:, **)
        parsed_response = JSON.parse(response.body)

        ctx[:firestore_name]  = parsed_response["name"]
        ctx[:id]              = ctx[:firestore_name].split("/").last
      end

      def error(ctx, response:, **)
        puts response.inspect
      end
    end
  end
end
