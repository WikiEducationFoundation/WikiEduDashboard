# frozen_string_literal: true

class GeneratePasscode
  DEFAULT_LENGTH = 8

  def self.call(length: DEFAULT_LENGTH)
    ('a'..'z').to_a.sample(length).join
  end
end
