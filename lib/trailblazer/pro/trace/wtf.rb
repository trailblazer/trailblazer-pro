module Trailblazer::Pro
  module Trace
    module Wtf
      module_function
      # DISCUSS: this is called inside the monkey-patch for Activity/Operation.()
      # in {Pro::Call.call}.
      def call(*args, present_options: {}, **options)
        global_present_options =  Session.wtf_present_options
        raise "[Trailblazer] Please configure your PRO API key." if global_present_options.nil?

        present_options =
          global_present_options
            .merge(present_options)
            .merge(session: Session.session)

        # We inject our PRO Debugger.call via {:render_method} here.
        # {Developer::Wtf.invoke} calls {puts}.
        returned = Trailblazer::Developer::Wtf.invoke( # identical to {Developer.wtf?}.
          *args,
          present_options: present_options,
          **options
        )

        returned_ctx = returned[-1]

        session, session_updated = returned_ctx[:session], returned_ctx[:session_updated]

        update_session!(session) if session_updated # DISCUSS: this is a hook for pro-rails, not a massive fan.

        returned
      end

      class << self
        alias invoke call
      end

      def update_session!(session)
        Session.session = session
      end
    end
  end
end
