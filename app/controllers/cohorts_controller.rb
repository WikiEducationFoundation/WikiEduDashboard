# frozen_string_literal: true
#= Controller for cohort data
class CohortsController < ApplicationController
  layout 'admin'
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
    csv_for_role(:students)
  end

  def instructors
    csv_for_role(:instructors)
  end

  private

  def csv_for_role(role)
    @cohort = Cohort.find_by(slug: csv_params[:slug])
    respond_to do |format|
      format.csv do
        filename = "#{@cohort.slug}-#{role}-#{Date.today}.csv"
        send_data @cohort.users_to_csv(role, course: csv_params[:course]),
                  filename: filename
      end
    end
  end

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
