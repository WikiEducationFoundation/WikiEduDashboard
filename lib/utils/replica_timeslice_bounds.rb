# frozen_string_literal: true

class ReplicaTimesliceBounds
  class << self
    def real_start(course, timeslice_start)
      [timeslice_start, course.start].max.strftime('%Y%m%d%H%M%S')
    end

    # Replica treats both bounds as inclusive, so subtract a second from the timeslice
    # end to avoid fetching boundary revisions for two adjacent timeslices.
    def real_end(course, timeslice_end)
      [timeslice_end - 1.second, course.end].min.strftime('%Y%m%d%H%M%S')
    end
  end
end
