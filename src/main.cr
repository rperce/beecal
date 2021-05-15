require "./secrets"
require "./beeminder"
require "./google"
APP = "beeminder-gcal"

authn = Auth.new(APP)
p goals **authn.beeminder

cal = Google::Calendar.new authn
p cal.events
