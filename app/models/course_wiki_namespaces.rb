# frozen_string_literal: true
# == Schema Information
#
# Table name: course_wiki_namespaces
#
#  id               :bigint           not null, primary key
#  namespace        :integer
#  courses_wikis_id :bigint
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
class CourseWikiNamespaces < ApplicationRecord
  belongs_to :courses_wikis
end
