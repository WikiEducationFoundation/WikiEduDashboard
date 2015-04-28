#= Controller for week functionality
class WeeksController < ApplicationController
  respond_to :html, :json

  def week_params
    params.require(:week).permit(:id, :title)
  end

  def new
    @course = Course.find_by_slug(params[:course_id])
    respond_with(@course)
  end

  def index
    @course = Course.find_by_slug(params[:course_id])
    respond_to do |format|
      format.json { render json: @course.weeks.as_json(include: :blocks) }
    end
  end

  def timeline_params
    params.permit(weeks: [
      :id,
      :deleted,
      :title,
      { blocks: [
        :id,
        :title,
        :kind,
        :content,
        :weekday,
        :week_id,
        :deleted,
        :gradeable_id,
        :is_gradeable
      ] }
    ])
  end

  def gradeable_block(block)
    return unless block.key?(:is_gradeable)
    gradeable = block['is_gradeable']
    if gradeable && (!block.key?(:gradeable_id) || block['gradeable_id'].nil?)
      @points = block['points'] || 10
      if block.key?(:id)
        item_id = block['id']
        @gradeable = Gradeable.create(
          gradeable_item_id: item_id,
          gradeable_item_type: 'block',
          points: @points
        )
      else
        @gradeable = Gradeable.create(points: @points)
      end
      block['gradeable_id'] = @gradeable.id
    elsif !gradeable && block.key?(:gradeable_id)
      if block.key?(:id)
        @block = Block.find(block['id'])
        unless @block.gradeable_id.nil?
          Gradeable.find(@block.gradeable_id).destroy
        end
      end
      block['gradeable_id'] = nil
    end
  end

  def update_util(model, object)
    if object['id'].nil?
      model.create object
    elsif object['deleted']
      model.destroy object['id']
    else
      model.update object['id'], object
    end
  end

  def mass_update
    @course = Course.find_by_slug(params[:course_id])
    timeline_params['weeks'].each do |week|
      blocks = week['blocks']
      week.delete 'blocks'
      if !week.key?(:course_id) || week['course_id'].nil?
        week['course_id'] = @course.id
      end
      @week = update_util Week, week

      next if week['deleted'] || blocks.blank?
      blocks.each do |block|
        block['week_id'] = @week.id
        gradeable_block block
        block.delete(:is_gradeable)
        update_util Block, block
      end
    end
    respond_to do |format|
      format.json { render json: @course.weeks.as_json(include: :blocks) }
    end
  end
end
