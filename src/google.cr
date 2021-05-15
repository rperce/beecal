require "http/client"
require "./secrets"

TAG = "Managed by beeminder-gcal-integration"

module Google
  class Calendar
    class Event
      include JSON::Serializable
      getter summary
      getter description
      getter transparency
      getter start
      @start : Hash(String, Time)
      @end : Hash(String, Time)

      def initialize(goal)
        @summary = "#{goal.missing} due for #{goal.slug}"
        @description = "https://www.beeminder.com/#{goal.user}/#{goal.slug}\n\n#{TAG}"
        @transparency = "transparent"
        @start = {"dateTime" => goal.losedate}
        @end = {"dateTime" => goal.losedate}
      end
    end

    API_BASE = "/calendar/v3"

    def initialize(@auth : Auth)
      @client = HTTP::Client.new URI.parse("https://www.googleapis.com")
      @cal_id = URI.encode_www_form(@auth.google["calendar_id"])
    end

    def session
      @auth.google_oauth2_session
    end

    def events
      self.session.authenticate(@client)
      @client.get("#{API_BASE}/calendars/#{@cal_id}/events").body
    end

    def beeminder_events
      uri = URI.parse("#{API_BASE}/calendars/#{@cal_id}/events")
      items = [] of JSON::Any
      next_page_token = nil
      loop do
        uri.query = URI::Params.encode({q: TAG, pageToken: next_page_token})
        self.session.authenticate(@client)
        resp = JSON.parse(@client.get(uri.to_s).body)
        items.concat(resp["items"].as_a)
        next_page_token = resp["nextPageToken"]? ? resp["nextPageToken"].as_s : nil
        break if next_page_token.nil? || next_page_token == ""
      end

      items
    end

    def add_goal_deadline(goal)
      self.session.authenticate(@client)
      @client.post(
        "#{API_BASE}/calendars/#{@cal_id}/events",
        headers: HTTP::Headers{"Content-Type" => "application/json"},
        body: Event.new(goal).to_json,
      )
    end

    def delete_event(event_id)
      self.session.authenticate(@client)
      @client.delete("#{API_BASE}/calendars/#{@cal_id}/events/#{event_id}")
    end
  end
end
