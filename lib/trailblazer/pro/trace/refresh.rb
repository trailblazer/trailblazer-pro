module Trailblazer::Pro
  module Trace
    class Refresh < Trailblazer::Activity::Railway
      step :refresh_id_token
      step Trace.method(:parse_response)
      step :extract_id_token
      step :extract_refresh_token
      step Signin.method(:decorate_id_token)

      def refresh_id_token(ctx, http: Faraday, refresh_token:, firebase_refresh_url:, **)
        ctx[:response] = http.post(
          firebase_refresh_url,
          {
            refresh_token:  refresh_token,
            grant_type:     "refresh_token"
          }.to_json,
          {'Content-Type'=>'application/json', "Accept": "application/json"}
        )

        ctx[:response].status == 200
      end

      def extract_id_token(ctx, parsed_response:, **)
        ctx[:id_token] = parsed_response["id_token"]
      end

      def extract_refresh_token(ctx, parsed_response:, **)
        ctx[:refresh_token] = parsed_response["refresh_token"]
      end
    end
  end
end
