# frozen_string_literal: true

module UsernameTestHelper
  def self.test_usernames
    [
      # Non-ASCII characters - Latin with diacritics
      'José',
      'François',
      'Müller',
      'Søren',
      'Łukasz',
      'İbrahim',
      'Αλέξανδρος',
      'Дмитрий'
    ]
  end
end
