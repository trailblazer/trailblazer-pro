module Trailblazer::Pro
  module Trace
    class Store < Trailblazer::Activity::Railway
      step :upload
      step :extract_id
      fail :http_error

      def upload(ctx, http: Faraday, firebase_upload_url:, data_to_store:, id_token:, firestore_fields_template:, **)
        fields = data_to_store[:fields].merge(firestore_fields_template)

        json_to_store = JSON.dump(data_to_store.merge(fields: fields))#.to_json

        # puts "@@@@@ DATA SIZE: #{json_to_store.size / 1024} kb"

        ctx[:response] = http.post(
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

      def http_error(ctx, **options)
        Client.error_message(ctx, message: "Upload failed.", **options)
      end
    end
  end
end
