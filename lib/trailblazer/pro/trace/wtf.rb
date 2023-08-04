module Trailblazer::Pro
  module Trace
    # cache the token for successive runs of {#wtf?}.
    module Wtf
      module_function
      def call(*args, present_options: {}, **options)
        session = Session.session

        present_options = Session.wtf_present_options
          .merge(present_options)
          .merge(session: session)

        returned = Trailblazer::Developer.wtf?(
          *args,
          present_options: present_options,
          **options
        )

        (session, trace_id, debugger_url, _trace_envelope, session_updated) = returned[-1]

        update_session!(session) if session_updated # DISCUSS: this is a hook for pro-rails, not a massive fan.

        returned
      end

      def update_session!(session)
        Session.session = session
      end
    end
  end
end
