# frozen_string_literal: true

module StudentProgress
  # Where a piece of student work lives, for the Canvas integration and the
  # course page's Assignments tab. No queries beyond the course's home wiki.
  module Links
    module_function

    # The module itself. return_to sends the end-of-training "return" to the
    # course page; by default it uses the referer, which from an LTI iframe
    # would be the launch URL.
    def training_url(course, training_module)
      "/training/#{course.training_library_slug}/#{training_module.slug}" \
        "?return_to=#{CGI.escape("/courses/#{course.slug}")}"
    end

    # The in-app page an exercise happens at, e.g. /courses/<slug>/verify_claim;
    # nil for exercises done in a sandbox.
    def exercise_path_url(course, training_module)
      return if training_module.exercise_path.blank?

      "/courses/#{course.slug}/#{training_module.exercise_path}"
    end

    # Where the student does an exercise: its in-app page if it has one,
    # otherwise the module's own training page.
    def exercise_url(course, training_module)
      exercise_path_url(course, training_module) || training_url(course, training_module)
    end

    # The fixed userspace page a sandbox exercise is done on, whether or not
    # the student has created it yet; nil for exercises without one.
    def exercise_sandbox_url(course, user, training_module)
      return unless training_module.sandbox_location

      "#{user.userpage_url(course)}/#{training_module.sandbox_location}"
    end
  end
end
