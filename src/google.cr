require "http/client"
require "./secrets"

module Google
  class Calendar
    API_BASE = "/calendar/v3"
    def initialize(@auth : Auth)
      @client = HTTP::Client.new URI.parse("https://www.googleapis.com")
    end

    def session() @auth.google_oauth2_session end

    def events()
      self.session.authenticate(@client)
      cal_id = URI.encode_www_form(@auth.google["calendar_id"])
      @client.get("#{API_BASE}/calendars/#{cal_id}/events")
    end
  end
end
