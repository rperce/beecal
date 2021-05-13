require "xdg"
require "toml"
require "log"

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

def auth(app)
  secrets = read_secrets(app)
  beeminder = secrets["beeminder"].as(Hash)

  {
    beeminder: {
      username:   beeminder["username"].as(String),
      auth_token: beeminder["auth_token"].as(String),
    },
  }
end
