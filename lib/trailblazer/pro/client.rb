module Trailblazer
  module Pro
    # Provides a valid JWT to authenticate against the PRO API.
    #
    # We always require an input {:session} and output a {:session}.
    # Internally, {Signin} and {Refresh} don't know about session, only kwargs.
    module Client
      module_function
      # session_initialized? --> <> --> valid? --> <> -----------------------------------> (o)
      #                           |                 | --> Refresh --V                       ^
      #                           | --> Signin --------------------->  rebuild_session -->  |
      #
      class Connect < Trailblazer::Activity::Railway
        step :session_signedin?,
          Output(:failure) => Path(track_color: :signin, connect_to: Track(:rebuild)) do # FIXME: move to after {valid?}
            # Signin only consumes {:api_key} and friends and doesn't know about {:session}.
            step Subprocess(Signin),
              In() => :session_to_args#,
              # Out() => Trace::Signin::SESSION_VARIABLE_NAMES
          end

        step Client.method(:valid?), In() => :session_to_args, Inject() => [:now],
          Output(:failure) => Path(track_color: :refresh, connect_to: Track(:rebuild)) do
            step Subprocess(Refresh), In() => :session_to_args
          end

        step :rebuild_session, magnetic_to: :rebuild # TODO: assert that success/failure go to right Track.

        def session_signedin?(ctx, session:, **)
          session.is_a?(Session)
        end

        def rebuild_session(ctx, session:, **)
          session_params = ctx.to_h.slice(*Signin::SESSION_VARIABLE_NAMES)

          session = Session.new(
            **session.to_h,  # old data
            **session_params, # new input
          )

          ctx[:session] = session
          ctx[:session_updated] = true
        end

        def session_to_args(ctx, session:, **)
          session.to_h
        end
      end
    end # Client
  end
end
