# frozen_string_literal: true

class Ticket < ApplicationRecord
  belongs_to :course
  belongs_to :owner, class_name: :User

  has_many :messages, dependent: :destroy

  module Statuses
    OPEN             = 0
    WAITING_RESPONSE = 1
    RESOLVED         = 2
  end

  validates :status, numericality: true, inclusion: {
    in: Statuses.constants.map { |c| Statuses.const_get c }
  }
end
