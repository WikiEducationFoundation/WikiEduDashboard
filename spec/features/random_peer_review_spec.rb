# frozen_string_literal: true

require 'rails_helper'

describe 'random peer reviews', type: :feature, js: true do
  let(:course) { create(:course) }
  let(:campaign) { create(:campaign) }
  let(:instructor) { create(:instructor) }
  let(:student1) { create(:user) }
  let(:student2) { create(:test_user) }

  before do
    create(:campaigns_course, campaign_id: campaign.id, course_id: course.id)
    JoinCourse.new(course: course, user: instructor, role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
    JoinCourse.new(course: course, user: student1, role: CoursesUsers::Roles::STUDENT_ROLE)
    JoinCourse.new(course: course, user: student2, role: CoursesUsers::Roles::STUDENT_ROLE)

    # Student1 assigned 2 articles, already reviewing 1 article
    create(:article, title: 'Football')
    create(:article, title: 'Basketball')
    create(:article, title: 'Tennis')
    create(:assignment, course: course, article_title: Article.first.title, user: student1,
           role: Assignment::Roles::ASSIGNED_ROLE, wiki: course.home_wiki, article: Article.first)
    create(:assignment, course: course, article_title: Article.second.title, user: student1,
           role: Assignment::Roles::ASSIGNED_ROLE, wiki: course.home_wiki, article: Article.second)
    create(:assignment, course: course, article_title: Article.third.title, user: student1,
           role: Assignment::Roles::REVIEWING_ROLE, wiki: course.home_wiki, article: Article.third)

    # Student2 assigned 2 articles, reviewing none
    create(:article, title: 'Skating')
    create(:article, title: 'Cricket')
    create(:assignment, course: course, article_title: Article.fourth.title, user: student2,
           role: Assignment::Roles::ASSIGNED_ROLE, wiki: course.home_wiki, article: Article.fourth)
    create(:assignment, course: course, article_title: Article.fifth.title, user: student2,
           role: Assignment::Roles::ASSIGNED_ROLE, wiki: course.home_wiki, article: Article.fifth)

    login_as(instructor, scope: :user)
    stub_oauth_edit
  end

  it 'displays message if no more can be assigned according to limits' do
    # Assigning one more revewing article to Student2
    article = Article.first
    create(:assignment, course: course, article_title: article.title, user: student2,
           role: Assignment::Roles::REVIEWING_ROLE, wiki: course.home_wiki, article: article)

    VCR.use_cassette 'assignments/random_peer_review' do
      visit "/courses/#{course.slug}/students/overview"
    end

    find('button', text: 'Assign random peer reviews').click
    expect(page).to have_content 'Each student is already reviewing atleast 1 articles(s)'
    find('button', text: 'OK').click

    sleep 2
    student1_peer_reviews = student1.assignments.where(role: Assignment::Roles::REVIEWING_ROLE)
                                    .pluck(:article_title)
    student2_peer_reviews = student2.assignments.where(role: Assignment::Roles::REVIEWING_ROLE)
                                    .pluck(:article_title)

    # Data remains same for both, no more assignments
    expect(student1_peer_reviews.length).to eq 1
    expect(student1_peer_reviews.first).to eq 'Tennis'
    expect(student2_peer_reviews.length).to eq 1
    expect(student2_peer_reviews.first).to eq article.title
  end

  it 'assigns correctly if peer review count is not set' do
    VCR.use_cassette 'assignments/random_peer_review' do
      visit "/courses/#{course.slug}/students/overview"
    end

    find('button', text: 'Assign random peer reviews').click
    # 2 - 1 (Student1 already reviewing an article)
    expect(page).to have_content 'total of 1'
    find('button', text: 'OK').click

    sleep 2
    student1_peer_reviews = student1.assignments.where(role: Assignment::Roles::REVIEWING_ROLE)
                                    .pluck(:article_title)
    student2_peer_reviews = student2.assignments.where(role: Assignment::Roles::REVIEWING_ROLE)
                                    .pluck(:article_title)

    # Student1 already reviewing 'Tennis', so assigned
    # no more articles as limit is 1 if peer_review_count not set
    expect(student1_peer_reviews.length).to eq 1
    expect(student1_peer_reviews.first).to eq 'Tennis'

    # Student2 assigned any of the two assigned articles of Student1
    expect(student2_peer_reviews.length).to eq 1
    expect(%w[Basketball Football].include?(student2_peer_reviews.first)).to eq true
  end

  it 'assigns correctly if peer review count is set' do
    course.flags[:peer_review_count] = 2
    course.save

    VCR.use_cassette 'assignments/random_peer_review' do
      visit "/courses/#{course.slug}/students/overview"
    end

    find('button', text: 'Assign random peer reviews').click
    # 4 - 1 (Student1 already reviewing an article)
    expect(page).to have_content 'total of 3'
    find('button', text: 'OK').click

    sleep 2
    student1_peer_reviews = student1.assignments.where(role: Assignment::Roles::REVIEWING_ROLE)
                                    .pluck(:article_title)
    student2_peer_reviews = student2.assignments.where(role: Assignment::Roles::REVIEWING_ROLE)
                                    .pluck(:article_title)

    # Student1 already reviewing 'Tennis'
    # Assigned any one of ['Skating', 'Cricket'] of Student2
    expect(student1_peer_reviews.length).to eq 2
    expect(student1_peer_reviews.first).to eq 'Tennis'
    expect(%w[Skating Cricket].include?(student1_peer_reviews.second)).to eq true

    # Student2 assigned both of the assigned articles of Student1
    # Working around randomness by sorting article titles
    expect(student2_peer_reviews.length).to eq 2
    expect(student2_peer_reviews.sort).to eq %w[Basketball Football]
  end
end
