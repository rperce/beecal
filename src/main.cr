require "./secrets"
require "./beeminder"
require "./google"
APP = "beeminder-gcal"

authn = Auth.new(APP)
bee = Beeminder.new authn

goals = bee.active_goals

cal = Google::Calendar.new authn
cal.beeminder_events.each do |event|
  slug = event["summary"].as_s.split(" ")[-1]
  goal = goals.find { |g| g.slug == slug }
  time = Time::Format::ISO_8601_DATE_TIME.parse(event["start"]["dateTime"].as_s)
  if goal.nil?
    Log.info { "Deleting event for goal #{slug} not returned by beeminder" }
    cal.delete_event event["id"].as_s
  elsif goal.losedate != time
    Log.info { "Deleting event for goal #{slug} with stale time" }
    cal.delete_event event["id"].as_s
  else
    Log.info { "Event for goal #{slug} is correct" }
    goals.delete goal
  end
end

goals.each do |goal|
  Log.info { "Creating event for goal #{goal.slug} at #{goal.losedate}" }
  cal.add_goal_deadline goal
end
