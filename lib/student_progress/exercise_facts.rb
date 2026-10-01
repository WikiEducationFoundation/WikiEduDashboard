# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/student_progress/links"
require_dependency "#{Rails.root}/lib/student_progress/rules"
require_dependency "#{Rails.root}/lib/student_progress/timeline"

module StudentProgress
  # Each roster student's state on each exercise module on the timeline.
  #
  # An exercise's completion is a per-course flag with no timestamp, so
  # `completed_at` is only set for exercises whose completion does record one:
  # those done at an in-app page (the fact-verification exercise sets
  # `completed_at` when the response is submitted). For the rest,
  # TrainingModulesUsers#completed_at means the student read the instruction
  # slides, not that they did the exercise, so it is not reported.
  class ExerciseFacts
    Exercise = Struct.new(:training_module, :completed, :completed_at, :in_progress,
                          :due_date, :sandbox_url, :exercise_url, :instructions_url,
                          :article_title, :article_url, keyword_init: true) do
      def completed?
        completed
      end

      def in_progress?
        in_progress
      end
    end

    def initialize(roster, timeline: Timeline.new(roster))
      @roster = roster
      @course = roster.course
      @timeline = timeline
    end

    def exercise_for(user, training_module)
      tmu = @roster.completions_for(user.id)[training_module.id]
      complete = Rules.exercise_complete?(tmu, @course)
      Exercise.new(training_module:, completed: complete,
                   completed_at: completed_at(tmu, training_module, complete),
                   in_progress: !complete && in_progress?(user, training_module),
                   due_date: @timeline.due_date_for(training_module),
                   **links(user, training_module), **article(tmu))
    end

    # Whether the student has started the exercise without finishing it. Only
    # detectable for the fact-verification exercise: taking a claim is the start
    # and submitting the response is what completes it. Sandbox exercises have
    # no comparable signal.
    def in_progress?(user, training_module)
      training_module.exercise_path == 'verify_claim' && @roster.claim_taken?(user.id)
    end

    private

    def completed_at(tmu, training_module, complete)
      return unless complete && training_module.exercise_path.present?

      tmu.completed_at
    end

    def links(user, training_module)
      { sandbox_url: Links.exercise_sandbox_url(@course, user, training_module),
        exercise_url: Links.exercise_path_url(@course, training_module),
        instructions_url: Links.training_url(@course, training_module) }
    end

    # The article an article-title exercise recorded (e.g. the biography the
    # student updated), once its edit was verified.
    def article(tmu)
      title = tmu&.exercise_article_title(@course.id)
      return { article_title: nil, article_url: nil } if title.blank?

      { article_title: title,
        article_url: "#{@course.home_wiki.base_url}/wiki/#{title.tr(' ', '_')}" }
    end
  end
end
