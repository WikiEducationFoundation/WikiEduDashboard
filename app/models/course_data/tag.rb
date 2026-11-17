# frozen_string_literal: true

# == Schema Information
#
# Table name: tags
#
#  id         :integer          not null, primary key
#  course_id  :integer
#  tag        :string(255)
#  key        :string(255)
#  created_at :datetime
#  updated_at :datetime
#

#= Tag model
class Tag < ApplicationRecord
  belongs_to :course

  def self.courses_tagged_with(tag)
    Course.where(id: Tag.where(tag:).pluck(:course_id))
  end

  Summary = Struct.new(:tag, :course_count, :latest_start)

  # One Summary per distinct tag, optionally narrowed to tags containing the
  # query, with the number of tagged courses and the latest course start date.
  def self.summaries(query: nil)
    scope = joins(:course).group(:tag).order(Arel.sql('COUNT(*) DESC'), :tag)
    scope = scope.where('tags.tag LIKE ?', "%#{sanitize_sql_like(query)}%") if query.present?
    scope.pluck(:tag, Arel.sql('COUNT(*)'), Arel.sql('MAX(courses.start)'))
         .map { |row| Summary.new(*row) }
  end
end
