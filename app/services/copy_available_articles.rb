# frozen_string_literal: true

#= Copies the Available Articles of one course into another course, as Available
#= Articles. Records are created directly from the source assignment's attributes,
#= with no wiki API calls, and (article_title, wiki_id) pairs already present in
#= the target are skipped.
class CopyAvailableArticles
  attr_reader :source_count, :created_count, :skipped_count

  def initialize(source:, target:, include_student_assigned: false, dry_run: false)
    @source = source
    @target = target
    @include_student_assigned = include_student_assigned
    @created_count = 0
    @skipped_count = 0
    dry_run ? count_only : copy_all
  end

  private

  # Available Articles are editing assignments (role 0) with no user. With
  # include_student_assigned, the articles students in the source course picked
  # are included too, which reconstructs the original pool before selections.
  def source_scope
    scope = @source.assignments.assigned
    @include_student_assigned ? scope : scope.available
  end

  # Deduplicate within the source: with retain_available_articles, a claimed
  # article exists both as the available row and as the student's copy.
  def candidates
    @candidates ||= source_scope.order(:id).uniq { |assignment| key_for(assignment) }
  end

  def existing_keys
    @existing_keys ||= @target.assignments.available.pluck(:article_title, :wiki_id).to_set
  end

  def key_for(assignment)
    [assignment.article_title, assignment.wiki_id]
  end

  def count_only
    @source_count = candidates.size
    @skipped_count = candidates.count { |assignment| existing_keys.include?(key_for(assignment)) }
  end

  def copy_all
    @source_count = candidates.size
    candidates.each do |assignment|
      if existing_keys.include?(key_for(assignment))
        @skipped_count += 1
      else
        copy(assignment)
      end
    end
  end

  # Non-bang create: a legacy title that no longer passes validation, or a
  # concurrent addition caught by the uniqueness validation, is counted as
  # skipped rather than aborting the batch.
  def copy(assignment)
    copied = Assignment.create(course: @target,
                               role: Assignment::Roles::ASSIGNED_ROLE,
                               user_id: nil,
                               article_title: assignment.article_title,
                               article_id: assignment.article_id,
                               wiki_id: assignment.wiki_id,
                               flags: { available_article: true })
    if copied.persisted?
      @created_count += 1
      existing_keys << key_for(copied)
    else
      @skipped_count += 1
    end
  end
end
