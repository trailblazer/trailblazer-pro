module Trailblazer
  module Pro
    # DISCUSS: do we want {id_token} here explicitely?
    # Data structure to hold all data values necessary to keep an authenticated
    # session with Firebase.
    class Session < Struct.new(:token, :id_token, :firebase_upload_url, :firestore_fields_template, :firebase_refresh_url, :refresh_token, keyword_init: true)
      singleton_class.attr_accessor :wtf_present_options
      singleton_class.attr_accessor :session

      def to_h
        return {} if not_signed_in?
        super
      end

      def valid?(**options)
        return if not_signed_in?
        token.valid?(**options)
      end

      def not_signed_in?
        token.nil?
      end
    end

    # TODO:
    #   pass session, e.g. from RAils/tmp
    #   different PRO hosts
    def self.initialize!(api_key:, **options)
      Session.wtf_present_options = {
        render_method:  Trailblazer::Pro::Debugger,
        api_key:        api_key,
        **options
      }

      Session.session = Trailblazer::Pro::Session.new()
    end
  end
end
