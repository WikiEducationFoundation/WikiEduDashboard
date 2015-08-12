class RecentActivity < ApplicationController

  def activity
    date = params[:date] || 7.days.ago
    class_eval("#{stat_name}Stat").get_records(date, params)
  end

end

