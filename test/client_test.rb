require "test_helper"


class ClientTest < Minitest::Spec
  it "what" do
    api_key = "tpka_f5c698e2_d1ac_48fa_b59f_70e9ab100604"

    signal, (ctx, _) = Trailblazer::Pro::Trace::Signin.invoke([{api_key: api_key}, {}])

    puts "@@@@@ #{signal.inspect}"
    pp ctx[:model]



    # firebase_uid = "8XBiJwOsvte0RuvJJDS08BJ2jOV2"
    firebase_uid = "qoPcKforvZXmg7sEkzWpShiPi5w2"


# trace

require "faraday"
    response = Faraday.new(url: "https://trb-pro-dev-default-rtdb.europe-west1.firebasedatabase.app")
          .post("/traces/#{firebase_uid}.json?auth=#{id_token}",
            {

                token: "bla",
              }.to_json,
              {'Content-Type'=>'application/json', "Accept": "application/json"})

        puts response.inspect
          # raise unless response.status == 200



# web api key AIzaSyDnism7mVXtAExubmGQMFw7t_KlMD3nA2M



# curl 'https://identitytoolkit.googleapis.com/v1/accounts:update?key=AIzaSyDnism7mVXtAExubmGQMFw7t_KlMD3nA2M' \
# -H 'Content-Type: application/json' \
# --data-binary \
# '{"idToken":"eyJhbGciOiJSUzI1NiIsImtpZCI6IjE2ZGE4NmU4MWJkNTllMGE4Y2YzNTgwNTJiYjUzYjUzYjE4MzA3NzMiLCJ0eXAiOiJKV1QifQ.eyJpc3MiOiJodHRwczovL3NlY3VyZXRva2VuLmdvb2dsZS5jb20vdHJiLXByby1kZXYiLCJhdWQiOiJ0cmItcHJvLWRldiIsImF1dGhfdGltZSI6MTY4MjQzNjQ2NywidXNlcl9pZCI6IjhYQmlKd09zdnRlMFJ1dkpKRFMwOEJKMmpPVjIiLCJzdWIiOiI4WEJpSndPc3Z0ZTBSdXZKSkRTMDhCSjJqT1YyIiwiaWF0IjoxNjgyNDM2NDY3LCJleHAiOjE2ODI0NDAwNjcsImVtYWlsIjoidXNlckBleGFtcGxlMi5jb20iLCJlbWFpbF92ZXJpZmllZCI6ZmFsc2UsImZpcmViYXNlIjp7ImlkZW50aXRpZXMiOnsiZW1haWwiOlsidXNlckBleGFtcGxlMi5jb20iXX0sInNpZ25faW5fcHJvdmlkZXIiOiJjdXN0b20ifX0.Ea3DgZRlmzwx-LEQSRsuuM6hIkS_iHPsQGh7_snotzs66lSsLkqbVNb2DSsPmO0Ucybd12YquA3MB0UNUUX2hIRN2uR2JVYN2BFzMDlal1Fes753ZPBuuRlGE6_b7qCNnL41p6UWY-Ucg_DF5hiQp6ksQCGbRujS74Yz_mZ0uvafmogCLaRbgO1f2ncoXqm0aVuE_t5Vlor4drKTW2LqM0jgHLuIZTVrQhq9mKhJCZ2SrHbhpLkSJPIdGYzw87HdvFP5G_I7kXd03OGLlUdTELs_JslhUF77naS1XcvtWQgzcRhraDuJ49xI6Lp7BSS9e7O822Vi6HgWacBY3aMc6Q","email":"nick@example2.com","returnSecureToken":true}'



#     curl 'https://securetoken.googleapis.com/v1/token?key=[API_KEY]' \
# -H 'Content-Type: application/x-www-form-urlencoded' \
# --data 'grant_type=refresh_token&refresh_token=[REFRESH_TOKEN]'



#     curl -X POST -d '{
#   "author": "alanisawesome",
#   "title": "The Turing Machine"
# }' 'https://trb-pro-dev-default-rtdb.europe-west1.firebasedatabase.app/traces/apotonick.json'


  end

#   it do
#     skip "we need to mock the server, first"

#     # puts token = Dev::Client.retrieve_token(email: "apotonick@gmail.com", host: "https://api.trailblazer.to")

#     json = Dev::Client.import(id: 3, email: "apotonick@gmail.com", host: "https://api.trailblazer.to", query: "?labels=validate%3Einvalid!%3E:failure")

#     File.write("sip-#{Time.now}.json", json)

#     duplicate = Dev::Client.duplicate(id: 2, email: "apotonick@gmail.com", host: "https://api.trailblazer.to")
#     puts "@@@@@ #{duplicate.id.inspect}"

#   end

#   let(:api_key) { ENV["API_KEY"] }

#   it do
#     skip "we need to mock the server, first"

#     puts token = Dev::Client.retrieve_token(email: "apotonick@gmail.com", api_key: api_key, host: "http://localhost:3000")

#     assert token =~ /\w+/

# # Client.new_diagram (private)
#     diagram = Dev::Client.new_diagram(token: token, email: "apotonick@gmail.com", host: "http://localhost:3000")

#     assert diagram.id > 0
#     _(diagram.body).must_equal [] # the JSON is already parsed?

# # Client.import (public)
#     json = Dev::Client.import(id: diagram.id, email: "apotonick@gmail.com", api_key: api_key, host: "http://localhost:3000")



#   # Currently, this brings you a *formatted* JSON document and additionally added data, such as labels for connections.
#     _(json).must_equal %{{
#   "elements": [

#   ]
# }}

# # Client.duplicate
#     duplicate = Dev::Client.duplicate(id: diagram.id, email: "apotonick@gmail.com", api_key: api_key, host: "http://localhost:3000")

#     assert duplicate.id > diagram.id
#     assert _(duplicate.body).must_equal([]) # FIXME: better test!
#   end
end
