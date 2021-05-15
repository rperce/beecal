require "xdg"
require "toml"
require "log"
require "oauth2"
require "kemal"
require "./google"

def find_secrets_file(app) : Path
  files = [Path["."].expand, Path.home / ".#{app}", XDG::DATA::HOME / app].map { |p| p / "secrets.toml" }
  files.each do |file|
    if File.exists? file
      if File.readable? file
        Log.info { "Using #{file}" }
        return file
      else
        Log.warn { "#{file} exists but is not readable, skipping" }
      end
    end
  end
  Log.error { "Fatal: no secrets.toml found. Checked #{files.join ", "}" }
  exit 1
end

alias Secrets = NamedTuple(
  beeminder: NamedTuple(
    username: String,
    auth_token: String),
  google: NamedTuple(
    calendar_id: String,
    client_id: String,
    client_secret: String,
    token: OAuth2::AccessToken?))

def read_secrets(file): Secrets
  secrets = TOML.parse(File.read(file))
  beeminder = secrets["beeminder"].as(Hash)
  google = secrets["google"].as(Hash)

  {
    beeminder: {
      username:   beeminder["username"].as(String),
      auth_token: beeminder["auth_token"].as(String),
    },
    google: {
      calendar_id:   google["calendar_id"].as(String),
      client_id:     google["client_id"].as(String),
      client_secret: google["client_secret"].as(String),
      token:         google["token"]? ? OAuth2::AccessToken.from_json(google["token"].as(String)) : nil,
    },
  }
end

class Auth
  getter secrets_file
  getter google_oauth2_session
  def beeminder() @secrets["beeminder"] end
  def google() @secrets["google"] end

  @secrets_file : Path
  @secrets : Secrets
  def initialize(@app : String)
    @secrets_file = find_secrets_file(@app)
    @secrets = read_secrets(@secrets_file)
    @google_oauth2_client = OAuth2::Client.new(
      client_id: @secrets["google"]["client_id"],
      client_secret: @secrets["google"]["client_secret"],
      host: "https://accounts.google.com/o/oauth2/auth",
      authorize_uri: "https://accounts.google.com/o/oauth2/auth",
      token_uri: "https://oauth2.googleapis.com/token",
      redirect_uri: "http://localhost:3000/beeminder-gcal/auth",
    )
    ensure_google_token
    @google_oauth2_session = OAuth2::Session.new(
      @google_oauth2_client,
      google["token"].not_nil!,
    ) do |sesh|
      write_token(sesh.access_token)
    end
  end


  def to_toml_string(secrets = @secrets)
    toml = <<-TOML
    [beeminder]
    username = "#{secrets["beeminder"]["username"]}"
    auth_token = "#{secrets["beeminder"]["auth_token"]}"

    [google]
    calendar_id = "#{secrets["google"]["calendar_id"]}"
    client_id = "#{secrets["google"]["client_id"]}"
    client_secret = "#{secrets["google"]["client_secret"]}"
    TOML
    if secrets["google"]["token"]?
      toml += <<-TOML
      \ntoken = "#{secrets["google"]["token"].to_json.to_s.gsub('"', "\\\"")}"
      TOML
    end

    toml
  end

  def ensure_google_token()
    unless google["token"].nil?
      return
    end

    scope = "https://www.googleapis.com/auth/calendar.events"
    authorize_uri = @google_oauth2_client.get_authorize_uri(scope)

    code = nil
    get "/beeminder-gcal/auth" do |env|
      code = env.params.query["code"]
      "<html><body>You can close this window.<script>window.close();</script></body></html>"
    end
    after_get "/beeminder-gcal/auth" do
      Kemal.stop
    end

    Process.run("xdg-open", [authorize_uri])
    Kemal.run

    if code.nil?
      Log.error { "Fatal: google authorization code not received" }
      exit 2
    end

    write_token(@google_oauth2_client.get_access_token_using_authorization_code(code.not_nil!))
  end

  def write_token(token)
    with_token = @secrets.merge({
      google: @secrets["google"].merge({
        token: token,
      }),
    })

    @secrets = with_token
    File.write(@secrets_file, to_toml_string(with_token))
  end

  def persist_token(session)
    self.write_token(session.access_token)
  end
end
