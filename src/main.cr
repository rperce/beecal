require "./secrets"
require "./beeminder"
APP = "beeminder-gcal"

p goals **auth(APP)["beeminder"]
