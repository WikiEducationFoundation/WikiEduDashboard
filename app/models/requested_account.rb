# frozen_string_literal: true

class RequestedAccount < ActiveRecord::Base
  belongs_to :course
end
