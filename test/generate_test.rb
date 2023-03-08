require "test_helper"
require "json"

class GenerateTest < Minitest::Spec
  it "works with pro's parsing" do
    collaboration_json = File.read("../pro-backend/test/concepts/diagram" + "/blog_post.collaboration.json")

    collaboration = Trailblazer::Pro::Generate::Representer::Collaboration.new(OpenStruct.new).from_json(collaboration_json)
    lifecycle_lane = collaboration.lanes.find { |lane| lane.name == "article moderation" }


    # assert_equal lifecycle_lane.type "lane"
    assert_equal lifecycle_lane.elements.size, 40

    create = lifecycle_lane.elements[1]
    assert_equal create.id, "Create"
    assert_equal create.type, "function-task-node"
    assert_equal create.links.size, 2
    assert_equal create.links[0].target_id, "throw-Create"
    assert_equal create.links[0].semantic, "success"
    assert_equal create.links[1].target_id, "create_invalid!"
    assert_equal create.links[1].semantic, "failure"

    suspend = lifecycle_lane.elements[2]
    assert_equal suspend.id, "suspend-d15ef8ea-a55f-4eed-a0e8-37f717d21c2f"
    assert_equal suspend.type, "suspend"
    assert_equal suspend.links.size, 0
    assert_equal suspend.data["resumes"], ["catch-Update", "catch-Notify approver"]
  end
end
