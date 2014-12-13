class Replica

  def self.connect_to_tool()
    url = "http://tools.wmflabs.org/wikiedudashboard/"
    Net::HTTP::get(URI.parse(url))
  end

end