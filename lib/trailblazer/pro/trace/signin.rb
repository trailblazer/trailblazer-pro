module Trailblazer::Pro
  module Trace
    class Signin < Trailblazer::Activity::Railway
      step :request_custom_token
      pass :extract_custom_token_and_fb_key
      step :request_id_token
      step :extract_id_token
      step :decorate_id_token

      def request_custom_token(ctx, http: Faraday, api_key:, **)
        ctx[:response] = http.new(url: "http://localhost:3000")
          .post(
            "/api/v1/signin_with_api_key",
            {
              api_key: api_key,
            }.to_json,
            {'Content-Type'=>'application/json', "Accept": "application/json"}
          )

        ctx[:response].status == 200
      end

      def extract_custom_token_and_fb_key(ctx, response:, **)
        data = JSON.parse(response.body)

        ctx[:custom_token]          = data["custom_token"]
        ctx[:firebase_web_api_key]  = data["firebase_web_api_key"]
      end

      def request_id_token(ctx, http: Faraday, firebase_web_api_key:, custom_token:, **)
        ctx[:response] = http.new(url: "https://identitytoolkit.googleapis.com")
          .post(
            "/v1/accounts:signInWithCustomToken?key=#{firebase_web_api_key}",
            {
              token:              custom_token,
              returnSecureToken:  true
            }.to_json,
            {'Content-Type'=>'application/json', "Accept": "application/json"}
          )

        ctx[:response].status == 200
      end

      def extract_id_token(ctx, response:, **)
        ctx[:id_token] = JSON.parse(response.body)["idToken"]
      end

      def decorate_id_token(ctx, id_token:, **)
        ctx[:model] = IdToken.new(id_token)
      end

      require "jwt"
      require "date"
      class IdToken
        def initialize(firebase_id_token)
          @firebase_id_token = firebase_id_token

          token, _ = JWT.decode(firebase_id_token, nil, false, algorithm: "RS256")
          iat = token["iat"]
          exp = token["exp"]

          expires_at = DateTime.strptime(exp.to_s, "%s")

          @expires_at = expires_at
          @token      = token
        end

        def valid?

          puts "id_token expires at #{expires_at}, that is in #{((expires_at - DateTime.now) * 24 * 60 * 60).to_i} seconds"
        end
      end
    end # Signin
  end
end
