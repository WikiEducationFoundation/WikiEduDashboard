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
  SCHOOL = 'Student Program'

  TITLE_FORMAT = 'Course %<sequence>d'

  # How many times a caller should re-roll the sequence when another course
  # takes the one it picked before it can save.
  MAX_ATTEMPTS = 5

  attr_reader :course_params, :original_params, :sequence

  def initialize(course_params, sequence: nil)
    @original_params = course_params
    @sequence = sequence || first_unused_sequence
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
    @course_params = @original_params.merge(title: title_for(@sequence), school: SCHOOL)
  end

  # Nothing stops an ordinary course from being created with a stand-in title
  # and school. Its slug would fail the duplicate check for any privacy-mode
  # course that drew the same number, every time, so skip numbers already used.
  def first_unused_sequence
    sequence = ConfidentialCourseDetail.next_sequence
    sequence += 1 while Course.exists?(school: SCHOOL, title: title_for(sequence))
    sequence
  end

  def title_for(sequence)
    format(TITLE_FORMAT, sequence:)
  end
end
