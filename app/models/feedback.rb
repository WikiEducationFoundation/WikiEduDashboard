class Feedback < ApplicationRecord
	belongs_to :assignment
	belongs_to :feedback
end
