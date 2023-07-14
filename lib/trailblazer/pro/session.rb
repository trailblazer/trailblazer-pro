module Trailblazer
  module Pro
    # DISCUSS: do we want {id_token} here explicitely?
    # Data structure to hold all data values necessary to keep an authenticated
    # session with Firebase.
    class Session < Struct.new(:expires_at, :jwt_token_exp, :id_token, :firebase_upload_url, :firestore_fields_template, :firebase_refresh_url, :firebase_signin_url, :refresh_token, :api_key, :trailblazer_pro_host, keyword_init: true)
      singleton_class.attr_accessor :wtf_present_options
      singleton_class.attr_accessor :session

      class Uninitialized < Struct.new(:api_key, :trailblazer_pro_host, keyword_init: true)
      end
    end

    # TODO:
    #   pass session, e.g. from RAils/tmp
    def self.initialize!(api_key:, **options)
      Session.wtf_present_options = {
        render_method:  Trailblazer::Pro::Debugger,
        # api_key:        api_key,
        # **options
      }

      Session.session = Trailblazer::Pro::Session::Uninitialized.new(api_key: api_key, **options)
    end
  end
end
