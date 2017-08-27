# frozen_string_literal: true

class AssignmentSuggestion < ApplicationRecord
  belongs_to :assignment
  belongs_to :user
end
