module Trailblazer::Pro
  module Trace
    class Signin < Trailblazer::Activity::Railway
      step :request_custom_token
      step :parse_response
      step :extract_custom_token
      step :extract_firebase_urls
      step :request_id_token
      step :extract_id_token
      step :decorate_id_token
      step :compute_firebase_upload_url

      def request_custom_token(ctx, http: Faraday, api_key:, trailblazer_pro_host: "http://localhost:3000", **)
        ctx[:response] = http.new(url: trailblazer_pro_host)
          .post(
            "/api/v1/signin_with_api_key",
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

      def extract_firebase_urls(ctx, parsed_response:, **)
        ctx[:firebase_signin_url] = parsed_response["firebase_signin_url"]
        ctx[:firebase_upload_url] = parsed_response["firebase_upload_url"] # needed in {Trace::Store}.
      end

      def compute_firebase_upload_url(ctx, firebase_upload_url:, id_token:, **)
        host, path = firebase_upload_url

        path = path.sub(":id_token", id_token)

        ctx[:firebase_upload_url] = [host, path]
      end

      def request_id_token(ctx, http: Faraday, firebase_signin_url:, custom_token:, **)
        host, path = firebase_signin_url

        ctx[:response] = http.new(url: host)
          .post(
            path,
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
