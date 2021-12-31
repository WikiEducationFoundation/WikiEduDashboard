# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/alerts/medicine_article_monitor"

def mock_mailer
  OpenStruct.new(deliver_now: true)
end

describe MedicineArticleMonitor do
  let(:mntor) { described_class.new }
  let(:course1) { create(:course, slug: 'slug-one') }
  let(:course2) { create(:course, slug: 'slug-two') }
  let(:student1) { create(:user, username: 'alice', email: 'student1@example.edu') }
  let(:med_article) { create(:article, title: 'my med title 2', mw_page_id: 222) }
  let(:content_expert) { create(:user, greeter: true) }
  let(:med_training_module) { create(:training_module, slug: 'editing-medical-topics') }

  describe '.med_article?' do
    it 'returns true for a WP med article' do
      VCR.use_cassette 'wp_med_article' do
        expect(mntor.med_article?('Colonic polypectomy')).to eq true
      end
    end

    it 'returns true for a WP med article with normalized title' do
      VCR.use_cassette 'wp_med_article_with_normalized_title' do
        expect(mntor.med_article?('Colonic_polypectomy')).to eq true
      end
    end

    it 'returns false for a non WP med article' do
      VCR.use_cassette 'non_wp_med_article' do
        expect(mntor.med_article?('Radiohead')).to eq false
      end
    end
  end

  describe '.create_alerts_for_no_med_training_for_course' do
    before do
      allow(mntor).to receive(:med_article?).and_return(true)
      allow_any_instance_of(AlertMailer).to receive(:alert).and_return(mock_mailer)
      create(:assignment, course_id: course2.id,
             user_id: student1.id,
             role: 0,
             article_id: med_article.id,
             article_title: med_article.title)
    end

    context 'When a WP med article without med training' do
      it 'creates an Alert' do
        expect { mntor.create_alerts_for_no_med_training_for_course }.to change(Alert, :count).by(1)
      end

      it 'does not creates another alert for a given assignment' do
        assignment = Assignment.first
        Alert.create!(type: 'NoMedTrainingForCourseAlert',
                      article_id: assignment.article_id,
                      course_id: assignment.course_id)

        expect { mntor.create_alert_for_no_med_training_for_course(assignment) }
          .to change(Alert, :count).by(0)
      end
    end

    context 'When a WP med article with med training' do
      let(:week1) { create(:week, course_id: course1.id) }

      before do
        create(:block, kind: Block::KINDS['assignment'],
               week_id: week1.id,
               content: 'block',
               training_module_ids: [med_training_module.id])
      end

      it 'does not create an Alert' do
        expect { mntor.create_alerts_for_no_med_training_for_course }
          .to change(Alert, :count).by(1)
      end
    end
  end
end
