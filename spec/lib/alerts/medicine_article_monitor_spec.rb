# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/alerts/medicine_article_monitor"

def mock_mailer
  OpenStruct.new(deliver_now: true)
end

describe MedicineArticleMonitor do
  let(:monitor) { described_class.new }
  let(:course1) { create(:course, slug: 'slug-one') }
  let(:course2) { create(:course, slug: 'slug-two') }
  let(:student1) { create(:user, username: 'alice', email: 'student1@example.edu') }
  let(:med_article) { create(:article, title: 'Appendectomy', mw_page_id: 222) }
  let(:content_expert) { create(:user, greeter: true) }
  let(:med_category) do
    create(:category,
           name: MedicineArticleMonitor::WIKI_PROJECT_MEDICINE_CAT,
           source: 'category',
           wiki_id: 1,
           article_titles: [])
  end

  before :all do
    TrainingModule.load_all
  end

  describe '.med_category' do
    context 'When WP Med category is present in DB' do
      before do
        create(:category,
               name: MedicineArticleMonitor::WIKI_PROJECT_MEDICINE_CAT,
               source: 'category',
               wiki_id: 1)
      end

      it 'returns the right category' do
        expect(monitor.med_category.name).to eq 'All_WikiProject_Medicine_pages'
      end
    end

    context 'When no WP Med category is present in DB' do
      it 'creates it' do
        expect { monitor }.to change(Category, :count).by(1)
      end
    end
  end

  describe '.refresh_med_article_titles' do
    context 'When must refresh' do
      it 'refresh titles by calling Category#refresh_titles' do
        allow(monitor.instance_variable_get(:@med_category))
          .to receive(:refresh_titles).and_return(true)
        allow(monitor).to receive(:must_refresh?).and_return(true)
        monitor.refresh_med_article_titles
        expect(monitor.instance_variable_get(:@med_category)).to have_received(:refresh_titles)
      end
    end

    context 'When must not refresh' do
      it 'does not hit the Category#refresh_titles method' do
        allow(monitor).to receive(:must_refresh?).and_return(false)
        expect(monitor.instance_variable_get(:@med_category)).not_to receive(:refresh_titles)
        monitor.refresh_med_article_titles
      end
    end
  end

  describe '.must_refresh?' do
    context 'When no article in med category' do
      it 'returns true ie must refresh' do
        expect(monitor.must_refresh?).to eq true
      end
    end

    context 'When last refresh dates from too long' do
      it 'must refresh' do
        populate_med_category
        med_category.update(updated_at: 2.days.ago)
        expect(monitor.must_refresh?).to eq true
      end
    end

    context 'When last refresh is recent' do
      it 'must NOT refresh' do
        populate_med_category
        med_category.updated_at = 4.hours.ago
        expect(monitor.must_refresh?).to eq false
      end
    end
  end

  describe '.med_article?' do
    before do
      populate_med_category
    end

    it 'returns true for a WP med article' do
      expect(monitor.med_article?('Colonic_polypectomy')).to eq true
    end

    it 'returns false for a non WP med article' do
      expect(monitor.med_article?('Radiohead')).to eq false
    end
  end

  describe '.create_alerts_for_no_med_training_for_course' do
    before do
      populate_med_category
      allow_any_instance_of(AlertMailer).to receive(:alert).and_return(mock_mailer)
      create(:assignment, course_id: course2.id,
             user_id: student1.id,
             role: 0,
             article_id: med_article.id,
             article_title: med_article.title,
             created_at: 4.hours.ago,
             updated_at: 4.hours.ago)
    end

    context 'When a WP med article without med training' do
      it 'creates an Alert' do
        expect { described_class.create_alerts_for_no_med_training_for_course }
          .to change(Alert, :count).by(1)
      end

      it 'does not creates another alert for a given assignment' do
        assignment = Assignment.first
        Alert.create!(type: 'NoMedTrainingForCourseAlert',
                      article_id: assignment.article_id,
                      course_id: assignment.course_id)

        expect { monitor.create_alert_for_no_med_training_for_course(assignment) }
          .to change(Alert, :count).by(0)
      end
    end

    context 'When a WP med article with med training' do
      let(:week1) { create(:week, course_id: course1.id) }

      before do
        create(:block, kind: Block::KINDS['assignment'],
               week_id: week1.id,
               content: 'block',
               training_module_ids: [11, 17, 23])
      end

      it 'does not create an Alert' do
        expect { monitor.create_alerts_for_no_med_training_for_course }
          .to change(Alert, :count).by(1)
      end
    end
  end

  private

  def populate_med_category
    titles = %w[Colonic_polypectomy Appendectomy Adenoma Brainstem]
    med_category.update(article_titles: titles)
  end
end
