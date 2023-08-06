module Trailblazer::Pro
  module Trace
    module Wtf
      module_function
      # DISCUSS: this is called inside the monkey-patch for Activity/Operation.()
      # in {Pro::Call.call}.
      def call(*args, present_options: {}, **options)
        present_options = Session.wtf_present_options
          .merge(present_options)
          .merge(session: Session.session)

        returned = Trailblazer::Developer::Wtf.invoke( # identical to {Developer.wtf?}.
          *args,
          present_options: present_options,
          **options
        )

        (session, trace_id, debugger_url, _trace_envelope, session_updated) = returned[-1]

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
