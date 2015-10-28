class TrainingModulesUsers < ActiveRecord::Base
  belongs_to :user

  def training_module
    TrainingModule.find(training_module_id)
  end
end
