# frozen_string_literal: true

require 'uri'

module ClaimLibrary
  # A rough label for what kind of page a citation URL points at, from the URL
  # alone. It is a hint for the person reading the source, prompting the
  # question of who is speaking: a journal article, a newspaper's opinion
  # section, a blog, a government site, or a database's front page that leads
  # nowhere in particular. It never decides a verdict.
  module SourceKind
    HOST_KINDS = [
      ['wikipedia', /wikipedia\.org\z/],
      ['journal', /ncbi\.nlm\.nih\.gov|europepmc|doi\.org|plos\.org|bmj\.com|springer|wiley|
                   sciencedirect|nature\.com|tandfonline|sagepub|oup\.com|jstor\.org|
                   cambridge\.org|frontiersin|mdpi\.com/x],
      ['blog', /blog/],
      ['government', /\.gov(\.[a-z]{2})?\z|\.nic\.in\z/]
    ].freeze

    PATH_KINDS = [
      ['opinion', %r{/commentisfree/|/opinion|/op-ed|/editorial|/comment/}],
      ['blog', %r{/blogs?/}]
    ].freeze

    def self.of(url)
      uri = URI.parse(url.to_s)
      return 'offline' if uri.host.nil?
      host = uri.host.downcase
      path = uri.path.to_s.downcase
      kind = HOST_KINDS.find { |_, pattern| host.match?(pattern) }&.first ||
             PATH_KINDS.find { |_, pattern| path.match?(pattern) }&.first
      kind || (path.delete('/').empty? ? 'database_home' : 'web')
    rescue URI::InvalidURIError
      'web'
    end
  end
end
