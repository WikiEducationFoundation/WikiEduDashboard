class OnboardUsersWithName < ActiveRecord::Migration
  def change
    User.where.not(real_name: nil).where.not(email: nil).update_all(onboarded: true)
  end
end
