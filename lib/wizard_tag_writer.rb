# frozen_string_literal: true

# Writes the tags that record which wizard options a course was built with.
#
# Only one tag per wizard key is allowed: making a given choice a second time
# overwrites the previous tag rather than adding a second one, so that a course
# whose wizard answers change ends up tagged with the new answer. The panels in
# NONEXCLUSIVE_KEYS are the exception — those allow several selections at once,
# so the wizard key and the chosen value together form the record key.
#
# Extracted from WizardTimelineManager so that the wizard and the admin-facing
# sandbox mode switch write tags through one implementation of that rule.
class WizardTagWriter
  NONEXCLUSIVE_KEYS = ['topics'].freeze

  def initialize(course)
    @course = course
  end

  # `tags` is a collection of objects indexable by :key and :tag, which covers
  # both permitted wizard params and plain symbol-keyed hashes.
  def write(tags)
    tags.each { |tag| write_one(tag[:key], tag[:tag]) }
  end

  def write_one(wizard_key, tag_value)
    key = record_key(wizard_key, tag_value)
    existing = Tag.find_by(course_id: @course.id, key:)
    return existing.update(tag: tag_value) if existing
    Tag.create(course_id: @course.id, tag: tag_value, key:)
  end

  private

  def record_key(wizard_key, tag_value)
    NONEXCLUSIVE_KEYS.include?(wizard_key) ? "#{wizard_key}-#{tag_value}" : wizard_key
  end
end
