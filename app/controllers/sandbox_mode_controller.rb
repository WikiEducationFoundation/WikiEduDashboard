# frozen_string_literal: true

#= Controller for switching a course between sandbox drafting and live editing
class SandboxModeController < ApplicationController
  respond_to :json
  before_action :require_admin_permissions

  def update
    course = Course.find_by!(slug: params[:course_id])
    result = SwitchCourseSandboxMode.new(course, no_sandboxes:)
    render json: {
      no_sandboxes:,
      added: result.added_blocks,
      removed: result.removed_blocks,
      unmatched: result.unmatched,
      unresolved: result.unresolved
    }
  end

  private

  def no_sandboxes
    ActiveModel::Type::Boolean.new.cast(params.require(:no_sandboxes))
  end
end
