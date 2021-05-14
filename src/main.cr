require "./secrets"
require "./beeminder"
require "./google"
APP = "beeminder-gcal"

authn = auth(APP)
p goals **authn["beeminder"]
# p calendar **authn["google"]
