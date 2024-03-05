require "test_helper"

class ApiTest < Minitest::Spec
  after { `rm tmp/b0f945.json` }

  it "we can import a collaboration in our PRO JSON format" do
    Trailblazer::Pro.initialize!(api_key: api_key, trailblazer_pro_host: trailblazer_pro_host)

    # Trailblazer::Pro::Editor::Import.invoke([{
    #     target_filename: "test/imported_json/9661db.json",
    #     session: Trailblazer::Pro::Session.session
    #   },
    #   {}
    # ])

    signal, (ctx, _) = Trailblazer::Developer.wtf?(Trailblazer::Pro::Editor::Import, [{
        diagram_slug: "b0f945",
        target_filename: "/tmp/b0f945.json",
        session: Trailblazer::Pro::Session.session
      },
      {}
    ])

    assert_equal signal.inspect, %(#<Trailblazer::Activity::End semantic=:success>)

    assert_equal File.read("/tmp/b0f945.json"), %({\"id\":3,\"type\":\"collaboration\",\"lanes\":[{\"id\":\"lifecycle\",\"type\":\"lane\",\"elements\":[{\"id\":\"Activity_0dgrwre\",\"label\":\"Create\",\"type\":\"task\",\"data\":{},\"links\":[{\"target_id\":\"throw-after-Activity_0dgrwre\",\"semantic\":\"success\"}]},{\"id\":\"catch-before-Activity_0dgrwre\",\"label\":null,\"type\":\"catch_event\",\"data\":{\"start_task\":true},\"links\":[{\"target_id\":\"Activity_0dgrwre\",\"semantic\":\"success\"}]},{\"id\":\"throw-after-Activity_0dgrwre\",\"label\":null,\"type\":\"throw_event\",\"data\":{},\"links\":[]},{\"id\":\"suspend-gw-to-catch-before-Activity_0dgrwre\",\"label\":null,\"type\":\"suspend\",\"data\":{\"resumes\":[\"catch-before-Activity_0dgrwre\"]},\"links\":[]}]}],\"messages\":[]}) # a particular eloquent diagram.
  end

  it "401 unauthorized because not owner of diagram " do
    Trailblazer::Pro.initialize!(api_key: api_key, trailblazer_pro_host: trailblazer_pro_host)

    signal, (ctx, _) = Trailblazer::Developer.wtf?(Trailblazer::Pro::Editor::Import, [{
        diagram_slug: "xxxfff",
        target_filename: "test/imported_json/xxxfff.json",
        session: Trailblazer::Pro::Session.session
      },
      {}
    ])

    # TODO: use endpoint to run, and 404, 401 paths
    assert_equal signal.inspect, %(#<Trailblazer::Activity::End semantic=:failure>)

    assert_equal File.exist?("test/imported_json/xxxfff.json"), false
  end

  it "401 unauthorized because wrong token" do

  end
end
