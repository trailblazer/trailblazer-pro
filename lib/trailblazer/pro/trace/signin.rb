module Trailblazer::Pro
  module Trace
    def self.parse_response(ctx, response:, **)
      ctx[:parsed_response] = JSON.parse(response.body)
    end

    require "jwt"
    require "date"
    def self.parse_jwt_token(ctx, id_token:, **)
      token, _ = JWT.decode(id_token, nil, false, algorithm: "RS256")

      ctx[:jwt_token_exp] = token["exp"]
      # ctx[:jwt_token] = token
    end

    def self.parse_expires_at(ctx, jwt_token_exp:, **)
      ctx[:expires_at] = parse_exp(jwt_token_exp)
    end

    def self.parse_exp(exp)
      DateTime.strptime(exp.to_s, "%s")
    end

    def self.valid?(ctx, now:, expires_at:, **)
# FIXME
      puts "id_token expires at #{expires_at}, that is in #{((expires_at - now) * 24 * 60 * 60).to_i} seconds"

      now < expires_at
    end

    class Signin < Trailblazer::Activity::Railway
      step :request_custom_token
      step Trace.method(:parse_response)
      step :extract_custom_token
      step :extract_data_for_firebase
      step :request_id_token
      step Trace.method(:parse_response), id: :parse_firebase_response
      step :extract_id_token
      step :extract_refresh_token
      step Trace.method(:parse_jwt_token)
      step Trace.method(:parse_expires_at)

      PRO_SIGNIN_PATH = "/api/v1/signin_with_api_key"

      # DISCUSS: this is the "outgoing" contract, the variables we should store in {session_params}.
      SESSION_VARIABLE_NAMES = [
        #:custom_token,
        :id_token, :refresh_token, :expires_at, :jwt_token_exp, :firebase_signin_url, :firebase_refresh_url, :firebase_upload_url, :firestore_fields_template
      ]

      def request_custom_token(ctx, http: Faraday, api_key:, trailblazer_pro_host: "https://pro.trailblazer.to", **) # DISCUSS: do we like the defaulting?
        ctx[:response] = http.post(
          "#{trailblazer_pro_host}#{PRO_SIGNIN_PATH}",
          {
            api_key: api_key,
          }.to_json,
          {'Content-Type'=>'application/json', "Accept": "application/json"}
        )

        ctx[:response].status == 200
      end

      def extract_custom_token(ctx, parsed_response:, **)
        ctx[:custom_token] = parsed_response["custom_token"]
      end

      def extract_data_for_firebase(ctx, parsed_response:, **)
        ctx[:firebase_signin_url]   = parsed_response["firebase_signin_url"] or return
        ctx[:firebase_refresh_url]  = parsed_response["firebase_refresh_url"] or return
        ctx[:firebase_upload_url]   = parsed_response["firebase_upload_url"] or return # needed in {Trace::Store}.
        ctx[:firestore_fields_template]  = parsed_response["firebase_upload_data"] or return
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

      def extract_id_token(ctx, parsed_response:, **)
        ctx[:id_token] = parsed_response["idToken"]
      end

      def extract_refresh_token(ctx, parsed_response:, **)
        ctx[:refresh_token] = parsed_response["refreshToken"]
      end
    end # Signin
  end
end
