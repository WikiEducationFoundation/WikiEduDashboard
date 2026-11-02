# frozen_string_literal: true
require 'csv'
require_dependency "#{Rails.root}/lib/analytics/histogram_plotter"

class OresPlotController < ApplicationController
  include CourseHelper

  def course_plot
    @course = find_course_by_slug(params[:id])
    require_course_visible(@course)
    @ores_changes_csv = HistogramPlotter.csv(course: @course)
    json_data = CSV.table(@ores_changes_csv).map(&:to_hash)
    render json: json_data
  end

  def delete_ores_data
    @course = find_course_by_slug(params[:id])
    require_course_visible(@course)
    HistogramPlotter.delete_csv(course: @course)
  end

  def refresh_ores_data
    delete_ores_data
    course_plot
  end

  def campaign_plot
    @campaign = Campaign.find_by slug: params[:slug]
    @ores_changes_csv = HistogramPlotter.csv(campaign: @campaign)
    json_data = CSV.table(@ores_changes_csv).map(&:to_hash)
    render json: json_data
  end
end
