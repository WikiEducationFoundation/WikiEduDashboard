# frozen_string_literal: true

class CourseWikisController < ApplicationController
  def update
    course_id = params[:course_id]
    wikis = course_wiki_params[:wikis]
    CourseWiki.where(course_id: course_id).delete_all
    # clear existing course wikis to update with new ones
    wikis.each do |wiki|
      wiki_id = Wiki.get_or_create(language: wiki[:language], project: wiki[:project]).id
      CourseWiki.create(course_id: course_id, wiki_id: wiki_id)
    end
    render json: {}, status: :ok
  end

  def wikis
    course_id = params[:course_id]
    wiki_ids = CourseWiki.where(course_id: course_id).pluck(:wiki_id)
    @wikis = Wiki.find(wiki_ids)
  end

  private

  # Never trust parameters from the scary internet, only allow the white list through.
  def course_wiki_params
    params.require(:course_wiki).permit(wikis: [:language, :project])
  end
end
