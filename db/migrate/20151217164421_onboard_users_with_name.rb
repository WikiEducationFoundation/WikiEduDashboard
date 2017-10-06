class OnboardUsersWithName < ActiveRecord::Migration[4.2]
  def change
    User.where.not(real_name: nil).where.not(email: nil).update_all(onboarded: true)
  end
end
