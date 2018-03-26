# frozen_string_literal: true
# User Decorator
class UserDecorator < SimpleDelegator
  def positions
    SpecialUsers.special_users.select { |_position, name| name == username }
                .keys.map(&:to_sym)
  end

  SpecialUsers::POSITIONS.each do |position|
    define_method position.to_s + '?' do
      return positions.include? position
    end

    define_method position.to_s + '!' do
      return Setting.set_hash('special_users', position, username)
    end
  end
end
