require "jwt"
require "date"

module Trailblazer::Pro
  module Client
    module_function

    def parse_response(ctx, response:, **)
      ctx[:parsed_response] = JSON.parse(response.body)
    end

    def parse_jwt_token(ctx, id_token:, **)
      token, _ = JWT.decode(id_token, nil, false, algorithm: "RS256")

      ctx[:jwt_token_exp] = token["exp"]
      # ctx[:jwt_token] = token
    end

    def parse_expires_at(ctx, jwt_token_exp:, **)
      ctx[:expires_at] = parse_exp(jwt_token_exp)
    end

    def parse_exp(exp)
      DateTime.strptime(exp.to_s, "%s")
    end

    def valid?(ctx, now:, expires_at:, **)
# FIXME
      puts "id_token expires at #{expires_at}, that is in #{((expires_at - now) * 24 * 60 * 60).to_i} seconds"

      now < expires_at
    end

    # DISCUSS: we could expose two failure termini here:
    #          1. (retrieving custom token failed)
    #          2. (retrieving id token failed)
    class Signin < Trailblazer::Activity::Railway
      step :request_custom_token
      fail :error_for_custom_token, Output(:success) => End(:failure)
      step Client.method(:parse_response)
      step :extract_custom_token
      step :extract_data_for_firebase
      step :request_id_token
      step Client.method(:parse_response), id: :parse_firebase_response
      step :extract_id_token
      step :extract_refresh_token
      step Client.method(:parse_jwt_token)
      step Client.method(:parse_expires_at)
      # left ->(ctx, response:, **) { puts response.status } #  FIXME: better error handling!

      PRO_SIGNIN_PATH = "/api/v1/signin_with_api_key"

      # DISCUSS: this is the "outgoing" contract, the variables we should store in {session_params}.
      SESSION_VARIABLE_NAMES = [
        #:custom_token,
        :id_token, :refresh_token, :expires_at, :jwt_token_exp, :firebase_signin_url, :firebase_refresh_url, :firebase_upload_url, :firestore_fields_template
      ]

      def request_custom_token(ctx, http: Faraday, api_key:, trailblazer_pro_host:, **)
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

      def error_for_custom_token(ctx, response:, trailblazer_pro_host:, **)
        ctx[:error_message] = %(Custom token couldn't be retrieved. HTTP status: #{response.status})
      end
    end # Signin
  end
end
