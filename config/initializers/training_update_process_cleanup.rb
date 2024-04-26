require_dependency "#{Rails.root}/lib/data_cycle/batch_update_logging"
require_dependency "#{Rails.root}/lib/training/training_base"

include BatchUpdateLogging

delete_pid_file(:training)
TrainingBase.new.update_process_state(0)
TrainingBase.new.clear_error_messages