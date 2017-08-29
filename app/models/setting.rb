# frozen_string_literal: true

#= Generic store of global settings, with a key mapping to a hash of associated data.
class Setting < ApplicationRecord
  serialize :value, Hash
end
