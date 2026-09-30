# frozen_string_literal: true

# Progress for the per-student "set up on Wikipedia" indicator line item
# (LtiLineItem::SETUP_TYPE). A student counts as set up once their LtiContext is
# linked — i.e. they launched from Canvas and connected a Wikipedia account via
# OAuth (LtiSession#link_lti_user sets user_id). Scores 1.0 when linked and 0.0
# while still unlinked. A connected student's 1.0 is pushed to the gradebook; the
# unlinked 0.0 is NOT seeded (SyncLtiGrades#skip_zero?), because Canvas has no LTI
# way to make this column not count toward the course total, so a pushed 0 would
# read as a failing 0%. Who-hasn't-connected is surfaced in the in-Canvas
# "Wikipedia account" roster instead.
class LtiSetupProgress
  attr_reader :score_given, :score_maximum, :comment

  SCORE_MAXIMUM = 1.0
  # User-facing gradebook score comments — operator-supplied.
  CONNECTED_COMMENT = '✓'
  NOT_CONNECTED_COMMENT = 'not connected'

  def initialize(context)
    @context = context
    @score_maximum = SCORE_MAXIMUM
    @score_given = context.linked? ? 1.0 : 0.0
    @comment = context.linked? ? CONNECTED_COMMENT : NOT_CONNECTED_COMMENT
  end

  def signature
    @signature ||= Digest::SHA1.hexdigest("setup|#{@score_given}|#{@comment}")
  end

  def gradable?
    true
  end
end
