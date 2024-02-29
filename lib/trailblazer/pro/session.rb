module Trailblazer
  module Pro
    # DISCUSS: do we want {id_token} here explicitely?
    # Data structure to hold all data values necessary to keep an authenticated
    # session with Firebase.
    class Session < Struct.new(:expires_at, :jwt_token_exp, :id_token, :firebase_upload_url, :firestore_fields_template, :firebase_refresh_url, :firebase_signin_url, :refresh_token, :api_key, :trailblazer_pro_host, keyword_init: true)
      singleton_class.attr_accessor :wtf_present_options
      singleton_class.attr_accessor :session
      singleton_class.attr_accessor :trace_guards

      self.trace_guards = Trailblazer::Pro::Trace::Decision.new([]) # here we say "don't trace anything!"
      # .trace_guards = Pro::Trace::Decision.new([->(*) { [Trace::Wtf, {}] }]) # always use Pro web/CLI tracing per default.

      class Uninitialized < Struct.new(:api_key, :trailblazer_pro_host, keyword_init: true)
      end

      def self.serialize(session)
        attributes = session.to_h
        attributes = attributes.slice(*(attributes.keys - [:expires_at]))

        JSON.dump(attributes)
      end

      def self.deserialize(json)
        data = JSON.parse(json)

        options = data.key?("jwt_token_exp") ? {expires_at: Client.parse_exp(data["jwt_token_exp"])} : {}

        data
          .merge(options) # TODO: use representer
          .collect { |k, v| [k.to_sym, v] }
          .to_h
      end
    end

    # TODO:
    #   pass session, e.g. from RAils/tmp
    def self.initialize!(api_key:, id_token: nil, render_wtf: true, **options)
      Session.wtf_present_options = {
        render_method:  Trailblazer::Pro::Debugger,
        render_wtf:     render_wtf,
        # api_key:        api_key,
        # **options
      }

      # FIXME: we're repeating code/knowledge from Client::Connect here.
      if id_token
        Session.session = Trailblazer::Pro::Session.new(api_key: api_key, id_token: id_token, **options)
      else
        Session.session = Trailblazer::Pro::Session::Uninitialized.new(api_key: api_key, **options)
      end
    end

    def self.trace_operations!(operation_hash)
      Trailblazer::Pro::Session.trace_guards = DSL.trace_operations(operation_hash)
    end

    module DSL
      module_function

      def trace_operations(operation_hash)
        decisions =
          if operation_hash == :all
            Trailblazer::Operation.extend(Trailblazer::Pro::Operation::Call)

            raise "implement me"
          elsif operation_hash.is_a?(Hash)
            operation_hash.collect do |operation, strategy| # DISCUSS: this can be easily made faster for runtime.
              operation.extend(Trailblazer::Pro::Operation::Call) # only extend selected OPs.

              strategy = Trailblazer::Pro::Trace::Wtf if strategy === true # defaulting.

              ->(activity, *) { activity == operation ? [strategy, {}] : false }
            end
          else
            []
          end

        Trace::Decision.new(decisions)
      end
    end
  end
end
