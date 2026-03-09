# Remove the 'cloneable' tag from all courses that are 'stay_in_sandbox'

sandboxed = Course.all.select { |c| c.stay_in_sandbox? }
sandoxed_cloneable = sandboxed.select { |c| c.tag?('cloneable') }
course_ids = sandboxed_cloneable.map(&:id)
tags = Tag.where(course_id: course_ids, tag: 'cloneable')
tags.destroy_all
