# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/student_progress/rules"
require_dependency "#{Rails.root}/lib/student_progress/timeline"

module StudentProgress
  # Each roster student's progress on each training-kind module on the
  # timeline: when they finished it, how far through its slides they are, and
  # whether it is overdue.
  #
  # `completed_at` is when the student last finished the module, which may
  # predate this course: module completion isn't recorded per course.
  class TrainingFacts
    # `slide_progress` is the fraction of slides reached (0.0–1.0), nil if not
    # started.
    Training = Struct.new(:training_module, :completed_at, :slide_progress, :due_date,
                          :overdue, keyword_init: true) do
      def completed?
        completed_at.present?
      end

      def overdue?
        overdue
      end
    end

    def initialize(roster, timeline: Timeline.new(roster))
      @roster = roster
      @timeline = timeline
    end

    def training_for(user, training_module)
      tmu = @roster.completions_for(user.id)[training_module.id]
      due_date = @timeline.due_date_for(training_module)
      complete = Rules.training_complete?(tmu)
      Training.new(training_module:, completed_at: complete ? tmu.completed_at : nil,
                   slide_progress: slide_progress(tmu, training_module), due_date:,
                   overdue: !complete && due_date.present? && Time.zone.today > due_date)
    end

    private

    # Position of the last slide reached in the module's own slide list. A slug
    # no longer in the module (content changed since) counts as not started.
    def slide_progress(tmu, training_module)
      return 1.0 if Rules.training_complete?(tmu)
      return if tmu&.last_slide_completed.blank?

      slugs = training_module.slide_slugs || []
      index = slugs.index(tmu.last_slide_completed)
      return if index.nil? || slugs.empty?

      (index + 1).to_f / slugs.size
    end
  end
end
