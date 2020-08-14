# airwatch-ruby

Add the gem to your Gemfile:

```ruby
gem 'airwatch-ruby'
```

Example usage:

```
require 'airwatch'

client = Airwatch::Client.new('as1111.awmdm.com', 'MY_API_KEY', email: 'admin@example.com', password: 'password')
client.apps_search # returns a list of apps
```