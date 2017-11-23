# frozen_string_literal: true

require "#{Rails.root}/lib/analytics/histogram_plotter"

class OresPlotController < ApplicationController
  def course_plot
    @course = Course.find_by slug: params[:id]
    @ores_changes_plot = HistogramPlotter.plot(course: @course, opts: { simple: true })
    render json: { plot_path: @ores_changes_plot }
  end
end
