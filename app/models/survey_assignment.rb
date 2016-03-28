class SurveyAssignment < ActiveRecord::Base
  belongs_to :survey
  has_and_belongs_to_many :cohorts

  def send_at
    {
      :days => send_date_days,
      :before => send_before,
      :relative_to => send_date_relative_to
    }
  end
end
