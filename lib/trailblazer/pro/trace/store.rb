# Store
# trace.json
# created_at
# name
# pro version
module Trailblazer::Pro
  module Trace
    class Store < Trailblazer::Activity::Railway
      step :upload

      def upload(ctx, url:, path:, **)
        response = Faraday.new(url: "https://trb-pro-dev-default-rtdb.europe-west1.firebasedatabase.app")
          .post("/traces/#{firebase_uid}.json?auth=#{id_token}",
            {

                token: "bla",
              }.to_json,
              {'Content-Type'=>'application/json', "Accept": "application/json"})
      end
    end
  end
end
