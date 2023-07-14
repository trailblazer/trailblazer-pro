module Trailblazer::Pro
  module Trace
    # cache the token for successive runs of {#wtf?}.
    module Wtf
      def self.call(*args, present_options: {}, **options)
        session = Session.session

        present_options = Session.wtf_present_options
          .merge(present_options)
          .merge(session.to_h)
          .merge(session: session)

        returned = Trailblazer::Developer.wtf?(
          *args,
          present_options: present_options,
          **options
        )

        (session, trace_id, debugger_url, _trace_envelope) = returned[-1]

        Session.session = session

        returned
      end
    end
  end
end
