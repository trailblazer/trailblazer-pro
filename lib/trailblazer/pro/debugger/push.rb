module Trailblazer
  module Pro
    module Debugger
      class Push < Trailblazer::Activity::Railway
        step Subprocess(Client::Connect), # TODO: assert that success/failure go to right Track.
          Output(:failure) => Track(:failure),
          id: :connect
        step Subprocess(Trailblazer::Pro::Trace::Store),
          In() => Client.method(:session_to_args),
          In() => [:data_to_store],
          Inject() => [:http],
          id: :store

        # DISCUSS: do we need an explicit error handler here?
        # fail :render_error

        # def render_error(ctx, error_message:, **)
        #   raise error_message.inspect
        # end
      end # Push
    end
  end
end
