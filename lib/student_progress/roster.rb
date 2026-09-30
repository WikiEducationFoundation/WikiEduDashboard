# frozen_string_literal: true

module StudentProgress
  # Course-wide data that every student's progress reads, loaded once per
  # request rather than once per student: the timeline blocks with their weeks,
  # the training modules those blocks reference, and — for a given set of
  # students — their module completions, their assignments, the live-article
  # timeslices behind those assignments, and who has taken a verification
  # claim, each fetched for the whole set in one grouped query. Every piece
  # loads on first read, so a caller pays only for what it uses.
  #
  # The Canvas integration builds one for the roster it shows (the LTI 1.1
  # instructor roster, a drill-down's linked students) or for one student (a
  # student's own launch), so both views run the same code. The per-student
  # Lti*Progress classes also work without one, loading on demand for a single
  # user, which is the grade sync's path.
  class Roster
    attr_reader :course, :user_ids

    def initialize(course:, user_ids:)
      @course = course
      @user_ids = Array(user_ids).compact.uniq
    end

    # The timeline's blocks in timeline order, with week and course loaded
    # (BlockDateManager reads both), so due dates are computed from memory.
    # `blocks.order` can be null; such a block goes at the start of its week
    # rather than failing the comparison.
    def blocks
      @blocks ||= @course.blocks.includes(:week, :course).to_a
                         .sort_by { |block| [block.week.order, block.order.to_i] }
    end

    # A block's training modules in the block's own order: Block#training_modules
    # without its query.
    def modules_for(block)
      block.training_module_ids.filter_map { |id| training_modules_by_id[id] }
    end

    # The course's training-kind modules as LtiTrainingProgress collects them:
    # every module the timeline references, minus exercises, in id order (what a
    # single `where(id:)` query returns, and the order the student overview lists
    # them in).
    def training_modules
      @training_modules ||= training_modules_by_id.values.sort_by(&:id).reject(&:exercise?)
    end

    # This user's TrainingModulesUsers for the timeline's modules, keyed by
    # training_module_id.
    def completions_for(user_id)
      completions_by_user.fetch(user_id, {})
    end

    # This user's assignments in the course, every role, with article, wiki, user
    # and course loaded (the article, sandbox and review-page URLs read the first
    # three; AssignmentPipeline, behind Assignment#status, reads the course).
    def assignments_for(user_id)
      assignments_by_user.fetch(user_id, [])
    end

    # The live-article timeslices with contributors for one assigned article,
    # loaded for every roster student's editing assignments at once.
    def timeslices_for(article_id)
      return [] if article_id.nil?

      timeslices_by_article.fetch(article_id, [])
    end

    # Whether this user has taken a claim in the fact-verification exercise:
    # its one "started but not submitted" signal.
    def claim_taken?(user_id)
      claim_taker_ids.include?(user_id)
    end

    private

    def training_modules_by_id
      @training_modules_by_id ||=
        TrainingModule.where(id: blocks.flat_map(&:training_module_ids).uniq).index_by(&:id)
    end

    def completions_by_user
      @completions_by_user ||=
        TrainingModulesUsers.where(user_id: @user_ids,
                                   training_module_id: training_modules_by_id.keys)
                            .group_by(&:user_id)
                            .transform_values { |tmus| tmus.index_by(&:training_module_id) }
    end

    def assignments_by_user
      @assignments_by_user ||= Assignment.where(course_id: @course.id, user_id: @user_ids)
                                         .includes(:article, :wiki, :user, :course).order(:id)
                                         .group_by(&:user_id)
    end

    # `non_empty` skips the slices with no contributors, which are the bulk of them.
    def timeslices_by_article
      @timeslices_by_article ||= begin
        article_ids = assignments_by_user.values.flatten.select(&:editing?)
                                         .filter_map(&:article_id).uniq
        ArticleCourseTimeslice.where(course_id: @course.id, article_id: article_ids)
                              .non_empty.group_by(&:article_id)
      end
    end

    def claim_taker_ids
      @claim_taker_ids ||= VerificationClaimAssignment.where(course_id: @course.id,
                                                             user_id: @user_ids)
                                                      .pluck(:user_id).to_set
    end
  end
end
