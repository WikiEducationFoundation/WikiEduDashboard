# frozen_string_literal: true

# Narrows a drill-down's roster to one student, for the launch that opens a single
# student's submission in Canvas (SpeedGrader, or the submission page).
#
# The drill-downs are built around a roster because that's what an instructor
# opening an assignment wants. SpeedGrader is the opposite: the instructor is
# looking at one student, and a whole-roster view there is no more use than
# Canvas's own "No Preview Available" — it says nothing about the student on
# screen (operator, 2026-08-05).
#
# A nil focus leaves the roster whole, so every other launch is untouched.
module LtiRosterFocus
  private

  def focused(contexts)
    return contexts if @focus_user.nil?

    contexts.select { |context| context.user_id == @focus_user.id }
  end
end
