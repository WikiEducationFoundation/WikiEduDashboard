# frozen_string_literal: true
require 'sidekiq/api'

# Quiet all process (don't fetch new jobs from Redis anymore).
Sidekiq::ProcessSet.new.each(&:quiet!)

# Wait for current jobs to finish.
works = Sidekiq::WorkSet.new
sleep(5.minutes) while works.size.positive?

puts 'Processes already quieted and no jobs running'
