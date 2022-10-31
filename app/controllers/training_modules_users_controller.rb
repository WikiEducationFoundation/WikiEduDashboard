# frozen_string_literal: true
  
class TrainingModulesUsersController < ApplicationController
  respond_to :json
  before_action :require_signed_in, only: [:create_or_update, :mark_exercise_complete]

  def index
    course = Course.find(params[:course_id])
    user = User.find_by(id: params[:user_id]) if params[:user_id]
    render 'courses/_blocks', locals: { blocks: course.blocks, course:, user: }
  end

  def create_or_update
    set_slide
    set_training_module_user
    return if @slide.nil?
    complete_slide if should_set_slide_completed?
    complete_module if last_slide?
    @completed = @training_module_user.completed_at.present?
    render_slide
  end

  def mark_exercise_complete
    set_training_module
    set_training_module_user
    block = Block.find(params[:block_id])
    mark_completion_status(params[:complete], block.course.id)

    render 'courses/_block', locals: { block:, course: block.course }
  end

  def find
    @find_training_slide ||= if is_number?(params[:slide_id])
      TrainingSlide.find_by(id: params[:slide_id])
    else
      TrainingSlide.find_by(slug: params[:slide_id])
    end
    find_corresponding_module
    find_corresponding_library
    redirect_to "/training/#{@library_slug}/#{@module_slug}/#{@find_training_slide.slug}"

  end

  def find_corresponding_module
    ts_slug = @find_training_slide.id
    @training_module = TrainingModule.all.find_each do |tm|
      ts = tm.slide_slugs
      @module_slug = tm.slug
      #puts ts.inspect
       ts_slug.in? ts 
        @module_slug
      
      
    end
     #categories = library.categories
     #@library_slug = library.slug
     #categories.each do |key, value|
      # puts key
      # puts value
      # if key == 'modules'
      #  puts value[1].each do |key, value|
      #    puts key
       #   puts value.include?(@find_training_module.slug)
       #   @library_slug
       # end
       #end
      #end
   # end
   end

   def find_corresponding_library
    @training_library = TrainingLibrary.all.find_each do |library|
     categories = library.categories
     @library_slug = library.slug
     categories.each do |key, value|
       puts key
       puts value
       if key == 'modules'
        puts value[1].each do |key, value|
          puts key
          puts value.include?(@module_slug)
          @library_slug
        end
       end
      end
    end
    end

  private
  def is_number?(string)
    string.to_i.to_s == string
  end

  def set_training_library
    @library = TrainingLibrary.find_by(slug: params[:library_id])
  end

  def set_training_module
    @training_module = TrainingModule.find_by(slug: params[:module_id])
  end

  def set_slide
    set_training_module
    @slide = TrainingSlide.find_by(slug: params[:slide_id])
  end

  def render_slide
    render json: { slide: @slide, completed: @completed }
  end

  def set_training_module_user
    @training_module_user = TrainingModulesUsers.create_or_find_by(
      user: current_user,
      training_module_id: @training_module.id
    )
  end

  def complete_slide
    @training_module_user.last_slide_completed = @slide.slug
    @training_module_user.save
  end

  def complete_module
    @training_module_user.update_attribute(:completed_at, Time.now.utc)
  end

  def last_slide?
    @training_module_user.training_module.slides.last.slug == @slide.slug
  end

  def should_set_slide_completed?
    @training_module_user.furthest_slide?(@slide.slug)
  end

  def mark_completion_status(value, course_id)
    @training_module_user.mark_completion(value, course_id)
    @training_module_user.save
  end

end
