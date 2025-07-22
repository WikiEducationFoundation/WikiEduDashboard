CoursesUsers.all.each do |course_user|
  course_user.update(real_name: course_user.user.real_name)
end