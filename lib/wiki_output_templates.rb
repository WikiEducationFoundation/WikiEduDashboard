# frozen_string_literal: true

module WikiOutputTemplates
  def template_name(templates_hash, key)
    raise InvalidKeyError unless templates_hash['default'].keys.include?(key)
    templates_hash['default'][key]
  end

  class InvalidKeyError < StandardError; end
end
