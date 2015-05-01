#= Controller for week functionality
class WeeksController < ApplicationController
  respond_to :html, :json

  def index
    @course = Course.find_by_slug(params[:course_id])
    respond_to do |format|
      format.json { render json: @course.weeks.as_json(include: :blocks) }
      # format.json { render json: @course.weeks.as_json(include: { blocks: { include: :gradeable }}) }
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
        :is_gradeable,
        { gradeable: [
          :id,
          :gradeable_item_id,
          :gradeable_item_type,
          :title,
          :points,
          :deleted
        ] }
      ] }
    ])
  end

  # def create_gradeable(block)
  #   return unless block.key?(:id)
  #   points = block['points'] || 10
  #   item_id = block['id']
  #   gradeable = Gradeable.create(
  #     gradeable_item_id: item_id,
  #     gradeable_item_type: 'block',
  #     points: points
  #   )
  #   block['gradeable_id'] = gradeable.id
  # end

  # def destroy_gradeable(block)
  #   return unless block.key?(:id)
  #   block = Block.find(block['id'])
  #   Gradeable.find(block.gradeable_id).destroy unless block.gradeable_id.nil?
  #   block['gradeable_id'] = nil
  # end

  # def gradeable_block(block)
  #   return unless block.key?(:is_gradeable)
  #   gradeable = block['is_gradeable']
  #   if gradeable && (!block.key?(:gradeable_id) || block['gradeable_id'].nil?)
  #     create_gradeable block
  #   elsif !gradeable && block.key?(:gradeable_id)
  #     destroy_gradeable block
  #   end
  # end

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
        gradeable = block['gradeable']
        block.delete 'gradeable'
        block['week_id'] = @week.id
        @block = update_util Block, block

        next if block['deleted'] || gradeable.nil?
        gradeable['gradeable_item_id'] = @block.id
        gradeable['gradeable_item_type'] = 'block'
        gradeable['points'] = gradeable['points'] || 10
        @gradeable = update_util Gradeable, gradeable
        @block.update(gradeable_id: @gradeable.id)
      end
    end
    respond_to do |format|
      format.json do
        render json: @course.as_json(
          include: { weeks: {
            include: { blocks: { include: :gradeable } }
          } }
        )
      end
    end
  end
end
