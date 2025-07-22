dups = CoursesUsers.all.group(:user_id, :role, :course_id).having('count(*) > 1').count
dups.each_key { |(userid, role, courseid)| CoursesUsers.where(user_id: userid, course_id: courseid, role: role).last.destroy }
