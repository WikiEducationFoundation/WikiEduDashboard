# frozen_string_literal: true

module UsernameTestHelper
  def self.test_usernames
    [
      # Non-ASCII characters - Latin with diacritics
      'josé',
      'françois',
      'müller',
      'søren',
      'Łukasz',
      'İbrahim',
      'Αλέξανδρος',
      'Дмитрий'
    ]
  end
end
