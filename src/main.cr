require "xdg"
require "toml"
require "log"

APP = "beeminder-gcal"
def read_secrets()
    files = [Path["."].expand, Path.home / ".#{APP}", XDG::DATA::HOME / APP].map { |p| p / "secrets.toml" }
    files.each do |file|
        if File.exists? file
            if File.readable? file
                Log.info { "Using #{file}" }
                return TOML.parse( File.read(file))
            else
                Log.warn { "#{file} exists but is not readable, skipping" }
            end
        end
    end
    Log.error { "Fatal: no secrets.toml found. Checked #{files.join ", "}" }
    exit 1
end

puts read_secrets
