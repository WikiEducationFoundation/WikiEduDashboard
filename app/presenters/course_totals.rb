# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/word_count"

#= Sums of the cached course stats over a set of courses, in the column order
# of CoursesPresenter::COURSE_SUMS_SQL.
CourseTotals = Data.define(:character_sum, :article_count, :new_article_count, :view_sum,
                           :user_count, :references_count, :uploads_in_use_count,
                           :upload_usages_count, :trained_count, :upload_count,
                           :course_count) do
  def word_count
    WordCount.from_characters(character_sum)
  end

  # Nil when there are no students, which the page shows as "—".
  def trained_percent
    return if user_count.zero?
    100 * trained_count.to_f / user_count
  end
end
