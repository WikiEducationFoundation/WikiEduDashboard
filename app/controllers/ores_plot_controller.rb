# frozen_string_literal: true

require "#{Rails.root}/lib/analytics/histogram_plotter"

class OresPlotController < ApplicationController
  def course_plot
    @course = Course.find_by slug: params[:id]
    plotter = HistogramPlotter.new(course: @course)
    @ores_changes_plot = plotter.major_edits_plot(simple: true)
    render json: { plot_path: @ores_changes_plot }
  end
end
