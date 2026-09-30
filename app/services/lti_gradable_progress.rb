# frozen_string_literal: true

# Which progress object computes what to report for one student on one gradebook
# column. The mapping lived inline in SyncLtiGrades until peer review made it a
# fourth case; it is the one place that has to know every column type, so it is
# worth being able to point at.
#
# Returns nil when the column can't be computed — a Block whose timeline block is
# gone. Callers treat that as "nothing to report".
module LtiGradableProgress
  def self.for(line_item:, context:, course:)
    case line_item.gradable_type
    when LtiLineItem::SETUP_TYPE
      LtiSetupProgress.new(context)
    when LtiLineItem::TRAINING_PROGRESS_TYPE
      LtiTrainingProgress.new(course, context.user)
    when LtiLineItem::PEER_REVIEW_TYPE
      LtiPeerReviewProgress.new(course, context.user)
    when 'Block'
      block = Block.find_by(id: line_item.gradable_id)
      block && LtiBlockProgress.new(block, context.user)
    end
  end
end
