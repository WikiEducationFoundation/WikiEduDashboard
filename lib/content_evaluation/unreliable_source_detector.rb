# frozen_string_literal: true

# Detects sources that are unreliable or possibly unreliable
# Based on https://en.wikipedia.org/wiki/User:Headbomb/unreliable.js

require_relative './unreliable_js_rules'

class UnreliableSourcesDetector
  def initialize(content)
    @content = content
  end

  # returns an array of rules violations, where each violation
  # is an array of [rule description, first match string, match count]
  def unreliable_sources
    unreliable_sources = []
    UNRELIABLE_JS_RULES.each do |rule|
      match = @content.match(rule[:regex])
      next if match.nil?
      unreliable_sources << [rule[:comment], match.to_s, match.length]
    end
    unreliable_sources
  end
end
