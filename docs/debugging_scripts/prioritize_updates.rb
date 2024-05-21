# If updates have been disrupted for a while, we want to prioritize the recent, low-edit-count ones
# that can be updated more quickly.

# First, pause the updates and clear the queues.

# See the breakdown of edit counts and decide some break points for dividing between queues
Course.ready_for_update.order(:revision_count).map(&:revision_count)

# I'm going to try putting courses with fewer than 1000 revions in the short queue,
# fewer than 10k in the medium queue, and the rest in the long queue.


Course.ready_for_update.order(:revision_count).each do |course|
  queue = case course.revision_count
          when 0..999
            'short_update'
          when 1000..9999
            'medium_update'
          when 10000..10000000
            'long_update'
          end 

  CourseDataUpdateWorker.update_course(course_id: course.id, queue: queue)
end