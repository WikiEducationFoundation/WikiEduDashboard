# frozen_string_literal: true

class TrainingSlidesController < ApplicationController
  before_action :set_training_module, only: [:add_slide, :remove_slide]
  respond_to :json

  def add_slide
    slide_params = params.require(:slide).permit(:title, :slug, :wiki_page)

    existing_slide = TrainingSlide.find_by(slug: slide_params[:slug])

    if existing_slide
      handle_existing_slide(existing_slide, slide_params)
    else
      create_and_add_new_slide(slide_params)
    end
  end

  def remove_slide
    slide_slugs = params.require(:slideSlugList)

    slide_slugs.each do |slug|
      @training_module.slide_slugs.delete(slug)
    end

    if @training_module.save
      render json: { status: 'success', message: 'Slides removed successfully' }, status: :ok
    else
      render json: { status: 'error', errorMessages: @training_module.errors.full_messages },
             status: :unprocessable_entity
    end
  end

  def update_slide
    slide_params = params.require(:slide).permit(:title, :slug, :wiki_page)
    @slide = TrainingSlide.find_by(slug: slide_params[:slug])

    if @slide
      return unless check_wiki_page_exist(slide_params[:wiki_page])

      # Check if wiki_page is updated
      if @slide.wiki_page != slide_params[:wiki_page]
        parse_slide_content(fetch_wikitext(slide_params[:wiki_page]))
      end

      # Check if title is updated
      @slide.update(title: slide_params[:title]) if @slide.title != slide_params[:title]
      render json: { status: 'success', message: 'Slides updated successfully' }, status: :ok
    else
      render json: { status: 'error',
                     errorMessages: [I18n.t('training.validation.slide_not_found')] },
             status: :not_found
    end
  end

  private

  def set_training_module
    @training_module = TrainingModule.find_by(slug: params[:module_id])
    render json: { error: 'Training module not found' }, status: :not_found unless @training_module
  end

  def create_and_add_new_slide(slide_params)
    @slide = TrainingSlide.new(slide_params)
    return unless check_wiki_page_exist(@slide.wiki_page)

    if @slide.save
      parse_slide_content(fetch_wikitext(@slide.wiki_page))
      @training_module.slide_slugs << @slide.slug
      @training_module.save
      render json: @slide, status: :created
    else
      render json: { status: 'error', errorMessages: @slide.errors.full_messages },
             status: :unprocessable_entity
    end
  end

  def check_wiki_page_exist(wiki_page)
    wikitext = fetch_wikitext(wiki_page)
    if wikitext.blank?
      render json: { status: 'error',
             errorMessages: [I18n.t('training.validation.wikipage_not_found')] },
             status: :unprocessable_entity
      return false
    end
    true
  end

  def fetch_wikitext(wiki_page)
    WikiApi.new(MetaWiki.new).get_page_content(wiki_page)
  end

  def parse_slide_content(wikitext)
    parser = WikiSlideParser.new(wikitext)
    @slide.update(
      title: parser.title,
      content: parser.content,
      assessment: parser.quiz
    )
  end

  def handle_existing_slide(existing_slide, slide_params)
    if existing_slide.wiki_page != slide_params[:wiki_page]
      render json: { status: 'error',
                     errorMessages: [I18n.t('training.validation.slide_slug_already_exist')] },
             status: :unprocessable_entity
      return
    end

    if @training_module.slide_slugs.include?(existing_slide.slug)
      render json: { status: 'error',
                     errorMessages: [I18n.t('training.validation.slide_already_exist')] },
             status: :unprocessable_entity
    else
      @training_module.slide_slugs << existing_slide.slug
      @training_module.save
      render json: existing_slide, status: :ok
    end
  end
end
