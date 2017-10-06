# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/importers/assigned_article_importer"

describe AssignedArticleImporter do
  it 'imports articles based on assignment titles' do
    create(:course, id: 1)
    create(:assignment, id: 101, article_title: 'Selfie', article_id: nil, course_id: 1)
    create(:assignment,
           id: 102,
           article_title: 'This_article_does_not_exist',
           article_id: nil,
           course_id: 1)
    VCR.use_cassette 'assignments_importer' do
      AssignedArticleImporter.import_articles_for_assignments
    end
    article = Article.find_by(title: 'Selfie')
    expect(article.mw_page_id).to eq(38956275)
    expect(Assignment.find(101).article_id).to eq(article.id)
    expect(Assignment.find(102).article_id).to be_nil
    expect(Assignment.all.count).to eq(2)
    expect(Assignment.where(article_id: nil).count).to eq(1)
  end
end
