# frozen_string_literal: true

# == Schema Information
#
# Table name: settings
#
#  id         :integer          not null, primary key
#  key        :string(255)
#  value      :text(65535)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

#= Generic store of global settings, with a key mapping to a hash of associated data.
class Setting < ApplicationRecord
  serialize :value, Hash
end
