# Set our default user agent for all the gems and places in our code that
# use Faraday for requests
Faraday.default_connection_options = { headers: { user_agent: ENV['user_agent'] } }