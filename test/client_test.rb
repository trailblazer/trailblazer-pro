require "test_helper"
require "trailblazer/developer"

class ClientTest < Minitest::Spec
  class Create < Trailblazer::Activity::Railway
    step :model

    def model(ctx, **)
      ctx[:model] = Object.new
    end
  end

  it "manual Signin and Upload" do
    api_key = "tpka_f5c698e2_d1ac_48fa_b59f_70e9ab100604"

    signal, (ctx, _) = Trailblazer::Developer.wtf?(Trailblazer::Pro::Trace::Signin, [{api_key: api_key}, {}])

    assert_equal signal.to_h[:semantic], :success

    assert ctx[:model].valid?

    assert id_token = ctx[:id_token]
    assert_equal ctx[:firebase_upload_url], [
      "https://trb-pro-dev-default-rtdb.europe-west1.firebasedatabase.app",
      "/traces/8KwCOTLeK3QdmgtVNUPwr0ukJJc2.json?auth=#{id_token}"]

    signal, (ctx, _) = Trailblazer::Developer.wtf?(Trailblazer::Pro::Trace::Store, [{firebase_upload_url: ctx[:firebase_upload_url], data_to_store: {a: 1}.to_json}, {}])

    assert ctx[:id] =~ /-N[\d\w]+/ # DISCUSS: not sure the regex always works?

# curl 'https://identitytoolkit.googleapis.com/v1/accounts:update?key=AIzaSyDnism7mVXtAExubmGQMFw7t_KlMD3nA2M' \
# -H 'Content-Type: application/json' \
# --data-binary \
# '{"idToken":"eyJhbGciOiJSUzI1NiIsImtpZCI6IjE2ZGE4NmU4MWJkNTllMGE4YYzNTgwNTJiYjUzYjUzYjE4MzA3NzMiLCJ0eXAiOiJKV1QifQ.eyJpc3MiOiJodHRwczovL3NlY3VyZXRva2VuLmdvb2dsZS5jb20vdHJiLXByby1kZXYiLCJhdWQiOiJ0cmItcHJvLWRldiIsImF1dGhfdGltZSI6MTY4MjQzNjQ2NywidXNlcl9pZCI6IjhYQmlKd09zdnRlMFJ1dkpKRFMwOEJKMmpPVjIiLCJzdWIiOiI4WEJpSndPc3Z0ZTBSdXZKSkRTMDhCSjJqT1YyIiwiaWF0IjoxNjgyNDM2NDY3LCJleHAiOjE2ODI0NDAwNjcsImVtYWlsIjoidXNlckBleGFtcGxlMi5jb20iLCJlbWFpbF92ZXJpZmllZCI6ZmFsc2UsImZpcmViYXNlIjp7ImlkZW50aXRpZXMiOnsiZW1haWwiOlsidXNlckBleGFtcGxlMi5jb20iXX0sInNpZ25faW5fcHJvdmlkZXIiOiJjdXN0b20ifX0.Ea3DgZRlmzwx-LEQSRsuuM6hIkS_iHPsQGh7_snotzs66lSsLkqbVNb2DSsPmO0Ucybd12YquA3MB0UNUUX2hIRN2uR2JVYN2BFzMDlal1Fes753ZPBuuRlGE6_b7qCNnL41p6UWY-Ucg_DF5hiQp6ksQCGbRujS74Yz_mZ0uvafmogCLaRbgO1f2ncoXqm0aVuE_t5Vlor4drKTW2LqM0jgHLuIZTVrQhq9mKhJCZ2SrHbhpLkSJPIdGYzw87HdvFP5G_I7kXd03OGLlUdTELs_JslhUF77naS1XcvtWQgzcRhraDuJ49xI6Lp7BSS9e7O822Vi6HgWacBY3aMc6Q","email":"nick@example2.com","returnSecureToken":true}'



#     curl 'https://securetoken.googleapis.com/v1/token?key=[API_KEY]' \
# -H 'Content-Type: application/x-www-form-urlencoded' \
# --data 'grant_type=refresh_token&refresh_token=[REFRESH_TOKEN]'



#     curl -X POST -d '{
#   "author": "alanisawesome",
#   "title": "The Turing Machine"
# }' 'https://trb-pro-dev-default-rtdb.europe-west1.firebasedatabase.app/traces/apotonick.json'


  end

  it "wtf?" do
    api_key = "tpka_f5c698e2_d1ac_48fa_b59f_70e9ab100604"

    ctx = {}

    signal, (ctx, _), _, output, (token, trace_id, debugger_url) = Trailblazer::Developer.wtf?(
      Create,
      [ctx, {}],
      present_options: {render_method: Trailblazer::Pro::Debugger, token: nil, api_key: api_key},
    )

    assert_equal token[0].valid?, true
    assert_match /^-N\w+/, trace_id
    assert_equal debugger_url, "https://ide.trailblazer.to/#{trace_id}"
  end
end
