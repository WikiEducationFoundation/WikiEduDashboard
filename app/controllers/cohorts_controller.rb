#= Controller for cohort data
class CohortsController < ApplicationController
  def students
    @cohort = Cohort.find_by(slug: params[:slug])
    respond_to do |format|
      format.csv do
        filename = "#{@cohort.slug}-students-#{Date.today}.csv"
        send_data @cohort.students_to_csv, filename: filename
      end
    end
  end
end
