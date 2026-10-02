# frozen_string_literal: true

# What a privacy-mode course actually stores in `title`, `school` and `slug`,
# derived from ObfuscateCourseIdentity so that fixtures mirror production
# instead of hardcoding the stand-ins.
module PrivacyModeHelpers
  def obfuscated_title(sequence = 1)
    format(ObfuscateCourseIdentity::TITLE_FORMAT, sequence:)
  end

  def obfuscated_school
    ObfuscateCourseIdentity::SCHOOL
  end

  def obfuscated_slug(term, sequence: 1)
    "#{obfuscated_school}/#{obfuscated_title(sequence)}_(#{term})".tr(' ', '_')
  end
end

RSpec.configure do |config|
  config.include PrivacyModeHelpers
end
