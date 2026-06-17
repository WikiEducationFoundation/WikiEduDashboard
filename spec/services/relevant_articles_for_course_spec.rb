# frozen_string_literal: true

require 'rails_helper'

describe RelevantArticlesForCourse do
  let(:wiki) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }

  def ended_course(subject)
    create(:course, subject:, slug: "Ended/#{subject}_#{SecureRandom.hex(4)}",
                    start: 2.years.ago, end: 6.months.ago)
  end

  def current_course(subject)
    create(:course, subject:, slug: "Current/#{subject}_#{SecureRandom.hex(4)}",
                    start: 1.month.ago, end: 1.month.from_now)
  end

  def article_in(course, title)
    article = create(:article, wiki:, title:, namespace: Article::Namespaces::MAINSPACE)
    create(:articles_course, course:, article:)
    article
  end

  it 'lists articles from ended courses matching the course subject' do
    otter = article_in(ended_course('Ecology'), 'Otter')
    article_in(ended_course('History'), 'Napoleon')
    result = described_class.new(current_course('Ecology')).articles
    expect(result).to contain_exactly(otter)
  end

  it 'falls back to articles from any ended course when no subject matches' do
    napoleon = article_in(ended_course('History'), 'Napoleon')
    result = described_class.new(current_course('Ecology')).articles
    expect(result).to contain_exactly(napoleon)
  end
end
