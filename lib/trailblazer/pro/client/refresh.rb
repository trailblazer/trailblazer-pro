module Trailblazer::Pro
  module Client
    class Refresh < Trailblazer::Activity::Railway
      step :refresh_id_token
      step Client.method(:parse_response)
      step :extract_id_token
      step :extract_refresh_token
      step Client.method(:parse_jwt_token)
      step Client.method(:parse_expires_at)

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
