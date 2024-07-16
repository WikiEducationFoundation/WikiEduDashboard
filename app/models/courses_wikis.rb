# frozen_string_literal: true
# == Schema Information
#
# Table name: courses_wikis
#
#  id         :bigint           not null, primary key
#  course_id  :integer
#  wiki_id    :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class CoursesWikis < ApplicationRecord
  validates :wiki_id, uniqueness: { scope: :course_id }

  belongs_to :course
  belongs_to :wiki
  has_many :course_wiki_namespaces, class_name: 'CourseWikiNamespaces', dependent: :destroy
  has_many :course_wiki_timeslices, lambda { |courses_wikis|
                                      where wiki: courses_wikis.wiki
                                    }, through: :course

  def update_namespaces(namespaces)
    update(course_wiki_namespaces: namespaces)
  end
end
