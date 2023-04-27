# Store
# trace.json
# created_at
# name
# pro version
module Trailblazer::Pro
  module Trace
    class Store < Trailblazer::Activity::Railway
      step :upload

      def upload(ctx, firebase_upload_url:, data_to_store:, **)
        host, path = firebase_upload_url

        response = Faraday.new(url: host)
          .post(
            path,
            data_to_store.to_json,
            {'Content-Type'=>'application/json', "Accept": "application/json"}
          )

        response.status == 200
      end
    end
  end
end
