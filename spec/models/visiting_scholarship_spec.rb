require 'rails_helper'

describe VisitingScholarship, type: :model do
  before do
    vs = create(:visiting_scholarship,
                id: 10001,
                start: 1.year.ago,
                end: Date.today + 1.year)
    scholar = create(:user)
    create(:courses_user,
           user_id: scholar.id,
           course_id: vs.id,
           role: CoursesUsers::Roles::STUDENT_ROLE)
    random_article = create(:article, title: 'Random', id: 1, namespace: 0)
    assigned_article = create(:article, title: 'Assigned', id: 2, namespace: 0)
    create(:assignment, user_id: scholar.id, course_id: vs.id,
                        article_id: 2, article_title: 'Assigned')
    create(:revision, id: 1, user_id: scholar.id,
                      article_id: random_article.id, date: 1.day.ago)
    create(:revision, id: 2, user_id: scholar.id,
                      article_id: assigned_article.id, date: 1.day.ago)
    Article.update_all_caches
    User.update_all_caches
    ArticlesCourses.update_from_course(vs)
    ArticlesCourses.update_all_caches
    CoursesUsers.update_all_caches
    Course.update_all_caches
  end

  let(:out_of_scope_rev) { Revision.find(1) }
  let(:in_scope_rev) { Revision.find(2) }
  let(:vs) { Course.find(10001) }

  it 'should only count assigned articles' do
    expect(vs.article_count).to eq(1)
  end
  it 'should only generate ArticlesCourses for assigned articles' do
    expect(vs.articles_courses.count).to eq(1)
  end
  it 'should only count revisions to assigned articles' do
    expect(vs.revision_count).to eq(1)
  end
  it 'should only count characters for assigned articles' do
    expect(vs.character_sum).to eq(in_scope_rev.characters)
  end
end
