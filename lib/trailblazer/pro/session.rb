module Trailblazer
  module Pro
    # DISCUSS: do we want {id_token} here explicitely?
    class Session < Struct.new(:token, :id_token, :firebase_upload_url, :firestore_fields_template)
      singleton_class.attr_accessor :wtf_options
      singleton_class.attr_accessor :session

      def to_h
        return {} if not_signed_in?
        super      end

      def valid?
        return if not_signed_in?
        token.valid?
      end

      def not_signed_in?
        token.nil?
      end
    end
  end
end
