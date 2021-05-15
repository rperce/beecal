# beecal

Tool to sync beeminder due-by deadlines to a google calendar.

## Installation

Download the `beecal` binary from the [latest
release](https://github.com/rperce/beecal/releases/latest).

Alternatively, build from source, assuming you use [crenv](https://github.com/crenv/crenv)
to manage your crystal version:
```shell
shards install
crystal build --release --progress src/main.cr -o beecal
```

## Usage

Set up your access tokens using the instructions below. Then, run the binary manually; it
will spin up an HTTP server. Point your browser at
`wherever.this.runs/beeminder-gcal/auth` and allow access with Google. Future runs should
refresh your access token manually and can be set up unsupervized, so at this point you
can create a cronjob that runs the script every ten minutes or so.

### Access Tokens
Obtain your [personal beeminder access
token](https://www.beeminder.com/api/v1/auth_token.json) and create a file named
`secrets.toml` in one of the following directories, checked in order:
* working directory from which this program is run
* `$HOME/.beeminder-gcal`
* `${XDG_DATA_HOME:$HOME/.local/share}/beeminder-gcal`

It should look like
```toml
[beeminder]
user = "your_username"
auth_token = "your_auth_token"
```

Then, open Google's [Developer Console](https://console.developer.google.com/). Create a
new Project---I have one for "Generic script API access"---and select Library in the left
sidebar. Search for "calendar" and select Google Calendar API. Click "Create Credentials"
in the main view, select "Google Calendar API" from the Credential Type dropdown, and
select "User data" in the radio buttons. Click "Next".

Fill in "beeminder-gcal-integration" for "App name" and select your own email under "User
support email" and fill it in under "Developer contact information". Click "Save and
continue" in the "Scopes" section. In the "OAuth Client ID" section, select "Desktop app"
in the "Application type" dropdown and leave "Name" as "Desktop client 1".

Now, in the sidebar, open "OAuth consent screen" and click "Add users" and "Test users".
Add yourself.

Go to the Credentials section in the sidebar, and click the Name of the client ID you just
created. Copy the Client ID and Client secret to your secrets.toml; it should now look
like this:
```toml
[beeminder]
user = "your_username"
auth_token = "your_auth_token"

[google]
calendar_id = "your_calendar_id"
client_id = "your_client_id"
client_secret = "your_client_secret"
```

You can use your primary calendar id (`your_email@gmail.com`, probably) or create a new
calendar for beeminder-gcal-integration; it will only edit events that claim to be
"Managed by beeminder-gcal-integration".

## Development

## Contributing

1. Fork it (<https://github.com/your-github-user/beeminder-gcal-integration/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Robert Perce](https://gitlab.com/rperce) - creator and maintainer
