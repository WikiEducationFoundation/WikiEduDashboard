# frozen_string_literal: true

# Swaps a course's real title and institution for obfuscated stand-ins, so that
# everything downstream of them — the slug, the on-wiki course page and its
# title, every JSON and CSV serialization — is anonymous without any per-site
# masking. The real values come back out in #detail_attributes, for storing in
# the admin-only ConfidentialCourseDetail record.
#
# Run this before CourseCreationManager#set_slug: the slug builder reads
# @course_params[:school] and [:title], and by then they are already obfuscated.
class ObfuscateCourseIdentity
  # [PLACEHOLDER - obfuscated institution name, shown in place of the real
  # school. It appears in every course URL and on-wiki course page title.]
  SCHOOL = 'Confidential'

  # [PLACEHOLDER - obfuscated course title. %<sequence>d is the course's
  # privacy-mode number, which is what makes the slug unique.]
  TITLE_FORMAT = 'Course %<sequence>d'

  # How many times a caller should re-roll the sequence when another course
  # takes the one it picked before it can save.
  MAX_ATTEMPTS = 5

  attr_reader :course_params, :original_params, :sequence

  def initialize(course_params, sequence: nil)
    @original_params = course_params
    @sequence = sequence || ConfidentialCourseDetail.next_sequence
    perform
  end

  # The real values, for the admin-only record.
  def detail_attributes
    { sequence: @sequence,
      real_title: @original_params[:title],
      real_school: @original_params[:school] }
  end

  private

  def perform
    @course_params = @original_params.merge(title: obfuscated_title, school: SCHOOL)
  end

  def obfuscated_title
    format(TITLE_FORMAT, sequence: @sequence)
  end
end
