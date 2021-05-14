require "xdg"
require "toml"
require "log"
require "oauth2"
require "kemal"

def read_secrets(app)
  files = [Path["."].expand, Path.home / ".#{app}", XDG::DATA::HOME / app].map { |p| p / "secrets.toml" }
  files.each do |file|
    if File.exists? file
      if File.readable? file
        Log.info { "Using #{file}" }
        return TOML.parse(File.read(file))
      else
        Log.warn { "#{file} exists but is not readable, skipping" }
      end
    end
  end
  Log.error { "Fatal: no secrets.toml found. Checked #{files.join ", "}" }
  exit 1
end

def generate_google_token(authorization_code)
  # TODO https://crystal-lang.org/api/1.0.0/OAuth2/Client.html
  # access_token = oauth2_client.get_access_token_using_authorization_code(authorization_code)
  # save to secrets.toml
end

def auth(app)
  secrets = read_secrets(app)
  beeminder = secrets["beeminder"].as(Hash)
  google = secrets["google"].as(Hash)

  typed = {
    beeminder: {
      username:   beeminder["username"].as(String),
      auth_token: beeminder["auth_token"].as(String),
    },
    google: {
      client_id: google["client_id"].as(String),
      client_secret: google["client_secret"].as(String),
    }
  }

  oauth2_client = OAuth2::Client.new(
    **typed["google"],
    host: "https://accounts.google.com/o/oauth2/auth",
    authorize_uri: "https://accounts.google.com/o/oauth2/auth",
    token_uri: "https://oauth2.googleapis.com/token",
    redirect_uri: "http://localhost:3000/beeminder-gcal/auth",
  )
  scope = "https://www.googleapis.com/auth/calendar.events"
  authorize_uri = oauth2_client.get_authorize_uri(scope)

  code = nil
  get "/beeminder-gcal/auth" do |env|
    code = env.params.query["code"]
    "<html><script>window.close();</script></html>"
  end
  after_get "/beeminder-gcal/auth" do
    Kemal.stop
  end

  Process.run("xdg-open", [authorize_uri])
  Kemal.run

  typed
end
