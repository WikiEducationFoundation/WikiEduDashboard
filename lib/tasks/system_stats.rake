# frozen_string_literal: true

namespace :system_stats do
  desc 'Run system stat update for today'
  task update: :environment do
    SystemStatUpdateWorker.new.perform
    puts "System stats updated for #{Time.zone.today}"
  end


end

namespace :facilitator_stats do
  desc 'Run facilitator stat update for today'
  task update: :environment do
    FacilitatorStatUpdateWorker.new.perform
    puts "Facilitator stats updated for #{Time.zone.today}"
  end
end
