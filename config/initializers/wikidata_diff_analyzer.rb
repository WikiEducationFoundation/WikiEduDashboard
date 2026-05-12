# Identify the dashboard to wikidata.org on every request the gem makes,
# so its sysadmins can route any traffic concerns to the right party.
# Without this, the gem's own default UA (which identifies the gem but
# not the consumer) would be sent.
WikidataDiffAnalyzer.user_agent = ENV['user_agent'] if ENV['user_agent']
