# frozen_string_literal: true

# Course-wide data that every student's in-Canvas progress reads, loaded once
# per request rather than once per student: the timeline blocks with their
# weeks, the training modules those blocks reference, and — for a given set of
# students — their module completions and their assignments, each fetched for
# the whole set in one grouped query.
#
# StudentStatusContext takes one of these and hands its pieces to
# LtiTrainingProgress and LtiBlockProgress; LtiPeerReviewProgress takes the
# assignments. Each of those also works without a preload, loading on demand
# for a single user, which is the grade sync's path. The LTI 1.1 instructor
# roster builds one for the whole enrollment, which is what keeps an instructor
# launch at a handful of queries however large the class is; a student's own
# launch builds one for that student alone, so both views run the same code.
class LtiProgressPreload
  attr_reader :course

  def initialize(course:, user_ids:)
    @course = course
    @user_ids = Array(user_ids)
  end

  # The timeline's blocks in timeline order, with week and course loaded
  # (BlockDateManager reads both), so due dates are computed from memory.
  def blocks
    @blocks ||= @course.blocks.includes(:week, :course).to_a
                       .sort_by { |block| [block.week.order, block.order] }
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
  # training_module_id: the shape LtiBlockProgress and LtiTrainingProgress read
  # completion from.
  def completions_for(user_id)
    completions_by_user.fetch(user_id, {})
  end

  # This user's assignments in the course, every role, with article, wiki, user
  # and course loaded (the article, sandbox and review-page URLs read the first
  # three; AssignmentPipeline, behind Assignment#status, reads the course).
  def assignments_for(user_id)
    assignments_by_user.fetch(user_id, [])
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
end
