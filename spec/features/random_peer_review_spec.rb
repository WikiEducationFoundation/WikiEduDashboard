# frozen_string_literal: true

require 'rails_helper'

describe 'random peer reviews', type: :feature, js: true do
  let(:course) { create(:course) }
  let(:campaign) { create(:campaign) }
  let(:instructor) { create(:instructor) }
  let(:student1) { create(:user) }
  let(:student2) { create(:test_user) }
  let(:football_article) { create(:article, title: 'Football') }
  let(:basketball_article) { create(:article, title: 'Basketball') }
  let(:hockey_article) { create(:article, title: 'Hockey') }
  let(:tennis_article) { create(:article, title: 'Tennis') }
  let(:skating_article) { create(:article, title: 'Skating') }
  let(:cricket_article) { create(:article, title: 'Cricket') }
  let(:polo_article) { create(:article, title: 'Polo') }

  before do
    create(:campaigns_course, campaign_id: campaign.id, course_id: course.id)
    JoinCourse.new(course:, user: instructor, role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
    JoinCourse.new(course:, user: student1, role: CoursesUsers::Roles::STUDENT_ROLE)
    JoinCourse.new(course:, user: student2, role: CoursesUsers::Roles::STUDENT_ROLE)

    # Student1 assigned 3 articles, already reviewing 1 article
    create(:assignment, course:, article_title: football_article.title, user: student1,
           role: Assignment::Roles::ASSIGNED_ROLE, wiki: course.home_wiki,
           article: football_article)
    create(:assignment, course:, article_title: basketball_article.title, user: student1,
           role: Assignment::Roles::ASSIGNED_ROLE, wiki: course.home_wiki,
           article: basketball_article)
    create(:assignment, course:, article_title: hockey_article.title, user: student1,
           role: Assignment::Roles::ASSIGNED_ROLE, wiki: course.home_wiki, article: hockey_article)
    create(:assignment, course:, article_title: tennis_article.title, user: student1,
           role: Assignment::Roles::REVIEWING_ROLE, wiki: course.home_wiki, article: tennis_article)

    # Student2 assigned 2 articles, reviewing none
    create(:assignment, course:, article_title: skating_article.title, user: student2,
           role: Assignment::Roles::ASSIGNED_ROLE, wiki: course.home_wiki, article: skating_article)
    create(:assignment, course:, article_title: cricket_article.title, user: student2,
           role: Assignment::Roles::ASSIGNED_ROLE, wiki: course.home_wiki, article: cricket_article)

    # Instructor is assigned an article as well, which should't be included among assigned reviews
    create(:assignment, course:, article_title: polo_article.title, user: instructor,
           role: Assignment::Roles::ASSIGNED_ROLE, wiki: course.home_wiki, article: polo_article)

    # Available articles not assigned to any student
    create(:assignment, course:, article_title: 'Article that does not exist',
           role: Assignment::Roles::ASSIGNED_ROLE, wiki: course.home_wiki)
    create(:assignment, course:, article_title: 'Another article that does not exist',
           role: Assignment::Roles::ASSIGNED_ROLE, wiki: course.home_wiki)

    login_as(instructor, scope: :user)
    stub_oauth_edit
  end

  it 'displays message if no more can be assigned according to limits' do
    # Assigning one more revewing article to Student2
    article = Article.first
    create(:assignment, course:, article_title: article.title, user: student2,
           role: Assignment::Roles::REVIEWING_ROLE, wiki: course.home_wiki, article:)

    VCR.use_cassette 'assignments/random_peer_review' do
      visit "/courses/#{course.slug}/students/overview"
    end

    find('button', text: 'Assign random peer reviews').click
    expect(page).to have_content 'Each student is already reviewing at least 1 articles(s)'
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

    within(all('tr.students').last) do
      expect(page).to have_content(/[Football|Basketball|Hockey]/)
    end

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
    expect(%w[Basketball Football Hockey].include?(student2_peer_reviews.first)).to eq true
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

    within(first('tr.students')) do
      expect(page).to have_content '2 articles'
    end

    student1_peer_reviews = student1.assignments.where(role: Assignment::Roles::REVIEWING_ROLE)
                                    .pluck(:article_title)
    student2_peer_reviews = student2.assignments.where(role: Assignment::Roles::REVIEWING_ROLE)
                                    .pluck(:article_title)

    # Student1 already reviewing 'Tennis'
    # Assigned any one of ['Skating', 'Cricket'] of Student2
    expect(student1_peer_reviews.length).to eq 2
    expect(student1_peer_reviews.first).to eq 'Tennis'
    expect(%w[Skating Cricket].include?(student1_peer_reviews.second)).to eq true

    # Student2 assigned two of the assigned articles of Student1
    expect(student2_peer_reviews.length).to eq 2
    expect((%w[Basketball Football Hockey] & student2_peer_reviews).length).to eq 2
  end
end
