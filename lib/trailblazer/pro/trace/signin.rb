module Trailblazer::Pro
  module Trace
    class Signin < Trailblazer::Activity::Railway
      step :request_custom_token
      step :parse_response
      step :extract_custom_token
      step :extract_data_for_firebase
      step :request_id_token
      step :extract_id_token
      step :decorate_id_token

      PRO_SIGNIN_PATH = "/api/v1/signin_with_api_key"

      def request_custom_token(ctx, http: Faraday, api_key:, trailblazer_pro_host: "http://localhost:3000", **)
        ctx[:response] = http.post(
          "#{trailblazer_pro_host}#{PRO_SIGNIN_PATH}",
          {
            api_key: api_key,
          }.to_json,
          {'Content-Type'=>'application/json', "Accept": "application/json"}
        )

        ctx[:response].status == 200
      end

      def parse_response(ctx, response:, **)
        ctx[:parsed_response] = JSON.parse(response.body)
      end

      def extract_custom_token(ctx, parsed_response:, **)
        ctx[:custom_token] = parsed_response["custom_token"]
      end

      def extract_data_for_firebase(ctx, parsed_response:, **)
        ctx[:firebase_signin_url]   = parsed_response["firebase_signin_url"] or return
        ctx[:firebase_upload_url]   = parsed_response["firebase_upload_url"] or return # needed in {Trace::Store}.
        ctx[:firestore_upload_template]  = parsed_response["firebase_upload_data"] or return
      end

      def request_id_token(ctx, http: Faraday, firebase_signin_url:, custom_token:, **)
        ctx[:response] = http.post(
          firebase_signin_url,
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
# FIXME
          puts "id_token expires at #{@expires_at}, that is in #{((@expires_at - DateTime.now) * 24 * 60 * 60).to_i} seconds"

          DateTime.now < @expires_at
        end
      end
    end # Signin
  end
end
