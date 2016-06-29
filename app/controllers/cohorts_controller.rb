#= Controller for cohort data
class CohortsController < ApplicationController
  before_action :require_admin_permissions,
                only: [:create]

  def index
    @cohorts = Cohort.all
  end

  def create
    @title = cohort_params[:title]
    # Strip everything but letters and digits, and convert spaces to underscores
    @slug = @title.downcase.gsub(/[^\w0-9 ]/, '').tr(' ', '_')
    if already_exists?
      render nothing: true, status: :ok
      return
    end

    Cohort.create(title: @title, slug: @slug)
    redirect_to '/cohorts'
  end

  def students
    @cohort = Cohort.find_by(slug: csv_params[:slug])
    respond_to do |format|
      format.csv do
        filename = "#{@cohort.slug}-students-#{Date.today}.csv"
        send_data @cohort.to_csv(course: csv_params[:course]), filename: filename
      end
    end
  end

  def instructors
    @cohort = Cohort.find_by(slug: csv_params[:slug])
    respond_to do |format|
      format.csv do
        filename = "#{@cohort.slug}-instructors-#{Date.today}.csv"
        send_data @cohort.to_csv(course: csv_params[:course], instructors: true),
                  filename: filename
      end
    end
  end

  private

  def already_exists?
    Cohort.exists?(slug: @slug) || Cohort.exists?(title: @title)
  end

  def cohort_params
    params.require(:cohort)
          .permit(:title)
  end

  def csv_params
    params.permit(:slug, :course)
  end
end
