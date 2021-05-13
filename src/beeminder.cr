require "http/client"
require "json"

API_PATH = "/api/v1/"

def api(path, params = nil)
  uri = URI.parse("https://www.beeminder.com").resolve(API_PATH + path)
  unless params.nil?
    uri.query = URI::Params.encode(params)
  end
  HTTP::Client.get uri
end

def goals(username, auth_token)
  resp = api("/users/#{username}.json", params: {auth_token: auth_token})
  JSON.parse(resp.body)["goals"].as_a.map { |x| x.to_s }
end
