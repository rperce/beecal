# beeminder-gcal-integration

TODO: Write a description here

## Installation

TODO: Write installation instructions here

## Usage

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

## Development

TODO: Write development instructions here

## Contributing

1. Fork it (<https://github.com/your-github-user/beeminder-gcal-integration/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Robert Perce](https://github.com/your-github-user) - creator and maintainer
