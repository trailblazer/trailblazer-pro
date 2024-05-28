require "test_helper"

require "trailblazer/test/operation/helper"
include Trailblazer::Test::Operation::Helper # FIXME: currently not being used!

# unit tests for {Pro::Debugger}
class DebuggerAPITest < Minitest::Spec
  let(:session_static_options) do
    {
      api_key: api_key,
      trailblazer_pro_host: trailblazer_pro_host,
      firebase_upload_url: "https://firestore.googleapis.com/v1/projects/trb-pro-dev/databases/(default)/documents/traces",
      firestore_fields_template: {"version"=>{"stringValue"=>"1"}, "uid"=>{"stringValue"=>"8KwCOTLeK3QdmgtVNUPwr0ukJJc2"}},
      firebase_refresh_url: "https://securetoken.googleapis.com/v1/token?key=AIzaSyDVZOdUrI6wOji774hGU0yY_cQw9OAVwzs",
    }
  end # FIXME: do we need this?

  def stubbed_faraday(&block)
=begin
    # Example for changing the activity itself

    class FailingUpload
      def self.call(ctx, **)
        ctx[:response] = Struct.new(:status).new("failed because stubbed")
        return false
      end
    end

    patch = ->(*) { step FailingUpload, replace: :upload }
    stubbed_push = Trailblazer::Activity::DSL::Linear::Patch.(Trailblazer::Pro::Debugger::Push, [:store], patch)

    signal, (ctx, _) = Trailblazer::Developer.wtf?(stubbed_push, [{session: Trailblazer::Pro::Session.session}, {}])
=end

    # Alternatively, we can use real dependency injection.
    # https://lostisland.github.io/faraday/#/adapters/test-adapter
    stubs = Faraday::Adapter::Test::Stubs.new

    yield(stubs)

    Faraday.new { |builder| builder.adapter(:test, stubs) }
  end

  it "Push.() edge case, upload fails" do
    #@ We are testing an error in Connect()
    #@ then we are testing a problem in Store()
    # question now is how to make Store break, while Connect is working.

    # TODO: that'd be nice.
    # container_x = {
    #   "push/store/upload" => {
    #     http: Http::Fail.new
    #   }
    # }
    Trailblazer::Pro.initialize!(api_key: api_key, trailblazer_pro_host: trailblazer_pro_host)

    stubbed_http = stubbed_faraday do |stubs|
      stubs.post(session_static_options[:firebase_upload_url]) do
        [
          501,
          { 'Content-Type': 'application/json' },
          '{"name": "some canned response for testing"}'
        ]
      end
    end

    patch = ->(*) {
      step Subprocess(Trailblazer::Pro::Client::Signin),
        magnetic_to: :signin,
        Output(:failure) => Track(:failure), # FIXME: we need Railway() instead of Path(), or something equivalent?
        In() => Trailblazer::Pro::Client.method(:session_to_args),
        # we omit Inject() => [:http] here to force using the original, unstubbed Faraday instance. This sucks, of course, and must
        # be done either properly with Faraday's test adapter, or with a container.
        replace: :signin,
        id: :signin,
        Output(:success) => Track(:rebuild) # TODO: better patching support for elements in a Path()!
    }
    patched_push = Trailblazer::Activity::DSL::Linear::Patch.(Trailblazer::Pro::Debugger::Push, [:connect], patch)

    #@ Make {upload} return 501.
    signal, (ctx, _) = Trailblazer::Developer.wtf?(patched_push, [
      {
        session: Trailblazer::Pro::Session.session,
        http: stubbed_http,
        data_to_store: {fields: {a: 1}},
        firestore_fields_template: session_static_options[:firestore_fields_template],
      }, {}])

    assert_equal signal.inspect, %(#<Trailblazer::Activity::End semantic=:failure>)
    assert_equal ctx[:error_message], %(Upload failed. HTTP status: 501) # we stubbed the request to be {501}
    #@ we could, potentially, see the host on the outside, accessing {:session}.
    assert_equal ctx[:session].trailblazer_pro_host, "https://testbackend-pro.trb.to"
  end

  it "Push.() fails because {Signin} fails" do
    Trailblazer::Pro.initialize!(api_key: api_key, trailblazer_pro_host: trailblazer_pro_host)

    stubbed_http = stubbed_faraday do |stubs|
      stubs.post("#{trailblazer_pro_host}#{Trailblazer::Pro::Client::Signin::PRO_SIGNIN_PATH}") do
        [
          502,
          { 'Content-Type': 'application/json' },
          '{"name": "some canned response for testing"}'
        ]
      end
    end

    signal, (ctx, _) = Trailblazer::Developer.wtf?(Trailblazer::Pro::Debugger::Push, [
      {
        session: Trailblazer::Pro::Session.session,
        http: stubbed_http,
        data_to_store: {fields: {a: 1}},
        firestore_fields_template: session_static_options[:firestore_fields_template],
      }, {}])

    assert_equal signal.inspect, %(#<Trailblazer::Activity::End semantic=:failure>)
    assert_equal ctx[:error_message], %(Custom token couldn't be retrieved. HTTP status: 502)
    assert_equal ctx[:session].trailblazer_pro_host, "https://testbackend-pro.trb.to"
  end
end
