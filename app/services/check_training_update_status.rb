# app/services/timer_job.rb
class CheckTrainingUpdateStatus

    def self.schedule_check
      Thread.new do
        sleep 900 # 15 min
        check_complete_status
      end
    end
  
    def self.check_complete_status
      result = {}
      tables = [TrainingLibrary, TrainingModule, TrainingSlide]
      tables.each do |table|
        rows = table.where(update_status: 2)
        if rows.any?
          attribute_name = :update_error
          values = rows.pluck(attribute_name)
          result[table.name] = values
        end
      end
      if result.empty?
        result = 'Success'
      else
        raise result
    end

    def self.job_running?
      Thread.list.any? { |thread| thread.name == 'CheckTrainingUpdateStatus' }
    end
end
