# frozen_string_literal: true

# == Schema Information
#
# Table name: trigrams
#
#  id          :bigint           not null, primary key
#  trigram     :string(3)
#  score       :integer
#  owner_id    :integer
#  owner_type  :string(255)
#  fuzzy_field :string(255)
#
class Trigram < ApplicationRecord
  include Fuzzily::Model
end
