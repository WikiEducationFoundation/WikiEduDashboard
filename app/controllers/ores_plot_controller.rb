# frozen_string_literal: true
require 'csv'
require_dependency "#{Rails.root}/lib/analytics/histogram_plotter"

class OresPlotController < ApplicationController
  def course_plot
    @course = Course.find_by slug: params[:id]
    @ores_changes_csv = HistogramPlotter.csv(course: @course)
    json_data = CSV.table(@ores_changes_csv).map(&:to_hash)
    render json: json_data
  end
end
