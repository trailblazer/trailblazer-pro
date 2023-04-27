# Store
# trace.json
# created_at
# name
# pro version
module Trailblazer::Pro
  module Trace
    class Store < Trailblazer::Activity::Railway
      step :upload
      step :extract_id

      def upload(ctx, firebase_upload_url:, data_to_store:, **)
        host, path = firebase_upload_url

        ctx[:response] = Faraday.new(url: host)
          .post(
            path,
            data_to_store,
            {'Content-Type'=>'application/json', "Accept": "application/json"}
          )

        ctx[:response].status == 200
      end

      def extract_id(ctx, response:, **)
        parsed_response = JSON.parse(response.body)

        ctx[:id] = parsed_response["name"]
      end
    end
  end
end
