module Trailblazer::Pro
  module Trace
    # cache the token for successive runs of {#wtf?}.
    module Wtf
      def self.call(*args, **options)
        options = Session.wtf_options
          .merge(options)

        present_options = options[:present_options]
          .merge(Session.session.to_h)
          .merge(session: Session.session)


# DISCUSS: token in {:present_options}?
        options = options.merge(present_options: present_options)

        returned = Trailblazer::Developer.wtf?(*args, **options)

        (session, trace_id, debugger_url, _trace_envelope) = returned[-1]

        Session.session = session

        returned
      end
    end
  end
end
