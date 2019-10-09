# Destroy all the records with user_id 0
# No new ones should be created once we switch to setting the user server-side
TrainingModulesUsers.where(user_id: 0).destroy_all

# These are all the records where we have a duplicate TrainingModulesUsers record for the same user+module combination.
# We need delete the duplicates before adding a unique index.
duplicates = TrainingModulesUsers.select(:user_id, :training_module_id).group(:user_id, :training_module_id).having("count(*) > 1").size

# We want to keep either the earliest record that represents having completed the module, or just the earliest record
# if none record module completion.
duplicates.keys.each do |user_and_module|
  tmus = TrainingModulesUsers.where(user_id: user_and_module[0], training_module_id: user_and_module[1]).to_a
  keeper = tmus.detect { |tmu| tmu.completed_at.present? }
  keeper ||= tmus.first
  (tmus - [keeper]).each(&:destroy)
end
