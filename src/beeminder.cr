require "http/client"
require "json"
require "./secrets"

API_PATH = "/api/v1/"

class Beeminder
  class Goal
    getter slug
    getter goaldate
    getter losedate
    getter missing
    getter user

    def initialize(@slug : String, @goaldate : Time, @losedate : Time, @missing : String, @user : String)
    end

    def self.from_json_hash(goal, user)
      Goal.new(
        goal["slug"].as_s,
        Time.unix(goal["goaldate"].as_i64),
        # beeminder reports stamps one second before the deadline for... reasons
        Time.unix(goal["losedate"].as_i64 + 1),
        goal["limsum"].as_s.split(" ")[0],
        user
      )
    end
  end

  @[JSON::Field(key: "slug")]
  @user : String
  @token : String

  def initialize(auth : Auth)
    @user = auth.beeminder["username"]
    @token = auth.beeminder["auth_token"]
  end

  def api(path, params = {} of String => String)
    uri = URI.parse("https://www.beeminder.com").resolve(API_PATH + path)
    uri.query = URI::Params.encode(params.merge({"auth_token" => @token}))
    HTTP::Client.get uri
  end

  def active_goals
    JSON.parse(api("/users/#{@user}/goals.json").body).as_a.map do |goal|
      Goal.from_json_hash goal, @user
    end.select do |goal|
      Time.utc <= goal.goaldate
    end
  end
end
