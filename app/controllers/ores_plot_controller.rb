# frozen_string_literal: true
require 'csv'
require_dependency Rails.root.join('lib/analytics/histogram_plotter')

class OresPlotController < ApplicationController
  def course_plot
    @course = Course.find_by slug: params[:id]
    @ores_changes_csv = HistogramPlotter.csv(course: @course)
    json_data = CSV.table(@ores_changes_csv).map(&:to_hash)
    render json: json_data
  end

  def delete_ores_data
    @course = Course.find_by slug: params[:id]
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
