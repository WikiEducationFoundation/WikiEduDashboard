# frozen_string_literal: true

# Detects sources that are unreliable or possibly unreliable
# Based on https://en.wikipedia.org/wiki/User:Headbomb/unreliable.js

require_relative './unreliable_js_rules'

class UnreliableSourcesDetector
  def initialize(content)
    @content = content
  end

  def unreliable_sources
    unreliable_sources = []
    UNRELIABLE_JS_RULES.each do |rule|
      @content.scan(rule[:regex]).each do |match|
        unreliable_sources << [rule[:comment], match]
      end
    end
    unreliable_sources
  end
end
