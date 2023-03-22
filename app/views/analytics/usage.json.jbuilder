# frozen_string_literal: true

json.stats [
  { Name: 'Total Users', val: @user_count },
  { Name: 'OAuth Users', val: @logged_in_count },
  { Name: 'Course Instructors', val: @course_instructor_count },
  { Name: 'Home Wikis', val: @home_wiki_count },
  { Name: 'Wiki Interactions', val: @total_wikis_touched }
]

years = 2015..Time.zone.now.year
@yrs = 2015..Time.zone.now.year
json.years_count do
  json.array! @yrs
end
json.course_over_time years.map do
  json.merge! Course.all.order(:created_at).map do |c|
    i += 1
    [c.created_at, i.to_i]
  end
end
json.courses_data years.map do |year|
  courses = Course.where("year(created_at) = #{year}")
  json.merge! courses.count
end
json.editors_data years.map do |year|
  courses = Course.where("year(created_at) = #{year}")
  json.merge! CoursesUsers.with_student_role.where(course: courses).pluck(:user_id).uniq.count
end
json.leaders_data years.map do |year|
  courses = Course.where("year(created_at) = #{year}")
  json.merge! CoursesUsers.with_instructor_role.where(course: courses).pluck(:user_id).uniq.count
end
json.created_data years.map do |year|
  courses = Course.where("year(created_at) = #{year}")
  json.merge! courses.sum(:new_article_count)
end
json.edited_data years.map do |year|
  courses = Course.where("year(created_at) = #{year}")
  json.merge! courses.sum(:article_count)
end
json.revisions_data years.map do |year|
  courses = Course.where("year(created_at) = #{year}")
  json.merge! courses.sum(:revision_count)
end
json.links Wiki.all.order(:language, :project).each do |wiki|
  json.merge! ['/courses_by_wiki/' + wiki.domain, wiki.domain, Course.where(home_wiki: wiki).count]
end
