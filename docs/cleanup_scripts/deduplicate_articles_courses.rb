# frozen_string_literal: true
# If two (or more) course updates run at the same time, we end up with duplicate articles courses.
# This script deduplicate articles courses, deleting the first one.
# Note that you may need to deduplicate an article several times if the article appears three
# times or more.
dups = ArticlesCourses.all.group(:course_id, :article_id).having('count(*) > 1').count
dups.each_key do |(course_id, article_id)|
  ArticlesCourses.where(course_id:, article_id:).first.destroy
end
