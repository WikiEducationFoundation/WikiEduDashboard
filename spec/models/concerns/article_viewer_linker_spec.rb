require 'rails_helper'

describe ArticleViewerLinker do
  let(:course) { create(:course) }
  let(:article) { create(:article) }
  let(:articles_course) { create(:articles_course, course:, article:) }
  let(:revision_ai_score) do
    create(:revision_ai_score, course:, article:, revision_id: 123, wiki_id: 1, user_id: 1)
  end
  let(:ai_edit_alert) { create(:ai_edit_alert, course:, article:) }

  it 'lets an ArticlesCourses record generate an article viewer link' do
    expect(articles_course.article_viewer_link).not_to be_nil
    expect(articles_course.article_viewer_link).to include(course.slug)
    expect(articles_course.article_viewer_link).to include("showArticle=#{article.id}")
  end

  it 'lets a RevisionAiScore record generate an article viewer link' do
    expect(revision_ai_score.article_viewer_link).not_to be_nil
    expect(revision_ai_score.article_viewer_link).to include(course.slug)
    expect(revision_ai_score.article_viewer_link).to include("showArticle=#{article.id}")
  end

  it 'lets an AiEditAlert record generate an article viewer link' do
    expect(ai_edit_alert.article_viewer_link).not_to be_nil
    expect(ai_edit_alert.article_viewer_link).to include(course.slug)
    expect(ai_edit_alert.article_viewer_link).to include("showArticle=#{article.id}")
  end
end
