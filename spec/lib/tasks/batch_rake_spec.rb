require 'rails_helper'
# https://robots.thoughtbot.com/test-rake-tasks-like-a-boss

describe 'batch:update_constantly' do
  include_context 'rake'

  it 'calls lots of update routines' do
    expect(LegacyCourseImporter).to receive(:update_all_courses)
    expect(UserImporter).to receive(:update_users)
    expect(RevisionImporter).to receive(:update_all_revisions)
    expect_any_instance_of(RevisionScoreImporter).to receive(:update_revision_scores)
    expect(PlagiabotImporter).to receive(:find_recent_plagiarism)
    expect(Article).to receive(:update_all_caches)
    expect(ArticlesCourses).to receive(:update_all_caches)
    expect(CoursesUsers).to receive(:update_all_caches)
    expect(Course).to receive(:update_all_caches)
    expect(StudentGreeter).to receive(:greet_all_ungreeted_students)
    expect(Raven).to receive(:capture_message)
    subject.invoke
  end
end
