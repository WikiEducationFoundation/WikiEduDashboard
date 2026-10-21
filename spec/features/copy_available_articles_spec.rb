# frozen_string_literal: true

require 'rails_helper'

describe 'Copying Available Articles from another course', :js, type: :feature do
  let(:instructor) do
    create(:user, username: 'Professor Sage', wiki_token: 'foo', wiki_secret: 'bar')
  end
  let(:target) do
    create(:course, slug: 'University/Target_(Term)', title: 'Target', school: 'University',
                    term: 'Term', submitted: true)
  end
  let(:source) do
    create(:course, slug: 'University/Source_(Term)', title: 'Source', school: 'University',
                    term: 'Term', submitted: true)
  end

  before do
    [target, source].each do |course|
      course.campaigns << Campaign.first
      create(:courses_user, user: instructor, course:, role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
    end
    %w[Source_article_one Source_article_two].each do |title|
      create(:assignment, course: source, user_id: nil, role: 0, wiki_id: 1,
                          article_title: title, flags: { available_article: true })
    end
    login_as(instructor, scope: :user)
    stub_oauth_edit
    stub_raw_action
    stub_info_query
  end

  def open_copy_dialog
    visit "/courses/#{target.slug}/articles/available"
    find('#copy-available-articles-button').click
  end

  it 'copies the source course Available Articles after showing a preview' do
    open_copy_dialog
    fill_in 'copy-available-articles-source-url',
            with: "http://localhost/courses/#{source.slug}/articles/available"
    expect(page).to have_css('.copy-available-articles__preview p', text: '2 articles')
    find('.copy-available-articles .button.dark').click
    expect(page).to have_content 'Source article one'
    expect(page).to have_content 'Source article two'
    expect(target.assignments.available.count).to eq(2)
  end

  it 'previews only the articles not already present' do
    create(:assignment, course: target, user_id: nil, role: 0, wiki_id: 1,
                        article_title: 'Source_article_one', flags: { available_article: true })
    open_copy_dialog
    fill_in 'copy-available-articles-source-url', with: source.slug
    # The preview names the source with its full 'School - Title (Term)' title
    expect(page).to have_css('.copy-available-articles__preview p',
                             text: /Source \(Term\): 1 article$/)
  end
end
