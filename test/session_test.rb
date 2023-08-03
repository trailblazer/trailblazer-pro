require "test_helper"

class SessionTest < Minitest::Spec
  it "#serialize and #deserialize with {Session::Uninitialized}" do
    uninitialized_session = Trailblazer::Pro::Session::Uninitialized.new(api_key: "api_key_xxx")

    serialized = Trailblazer::Pro::Session.serialize(uninitialized_session)
    assert_equal serialized.size, 53 # TODO: assess test.

    session = Trailblazer::Pro::Session.deserialize(serialized)

    assert_equal session.inspect, %({:api_key=>"api_key_xxx", :trailblazer_pro_host=>nil})
  end
end
