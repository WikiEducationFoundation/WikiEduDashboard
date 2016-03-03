class SurveysController < ApplicationController
  def test
    binding.pry
  end

  def clone
    clone = Rapidfire::QuestionGroup.find(params[:id]).deep_clone include: [:questions]
    clone.name = "#{clone.name} (Copy)"
    clone.save
    redirect_to rapidfire.question_groups_path
  end
end