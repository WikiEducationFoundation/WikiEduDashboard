# frozen_string_literal: true

class CoursesWikisController < ApplicationController
  def update
    course = Course.find(params[:course_id])
    new_wikis = course_wiki_params[:wikis]

    # Used to differentiate deleted wikis
    old_wiki_ids = course.wikis.pluck(:id)
    new_wiki_ids = []

    # Create an association for each new wiki
    new_wikis.each do |wiki|
      wiki_id = Wiki.get_or_create(language: wiki[:language], project: wiki[:project]).id
      new_wiki_ids.push(wiki_id)
      CoursesWikis.create(course_id: course.id, wiki_id: wiki_id)
    end

    # Delete removed wikis
    wikis_to_be_deleted = old_wiki_ids - new_wiki_ids
    CoursesWikis.where(course_id: course.id, wiki_id: wikis_to_be_deleted).delete_all

    render json: {}, status: :ok
  end

  def wikis
    course = Course.find(params[:course_id])
    wiki_ids = course.wikis.pluck(:id)
    @wikis = Wiki.find(wiki_ids)
  end

  private

  # Never trust parameters from the scary internet, only allow the white list through.
  def course_wiki_params
    params.require(:courses_wikis).permit(wikis: [:language, :project])
  end
end
