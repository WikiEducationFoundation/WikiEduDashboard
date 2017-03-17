# frozen_string_literal: true
require 'rails_helper'
require "#{Rails.root}/lib/training/training_loader"
require "#{Rails.root}/lib/training_slide"

describe TrainingLoader do
  describe '#load_content' do
    let(:content_class) { TrainingSlide }
    let(:subject) do
      TrainingLoader.new(content_class: content_class,
                         path_to_yaml: "#{Rails.root}/training_content/none/*.yml",
                         trim_id_from_filename: false,
                         wiki_base_page: 'Training modules/dashboard/slides-test')
    end
    before do
      allow(Features).to receive(:wiki_trainings?).and_return(true)
      Rails.cache.clear
    end
    after do
      Rails.cache.clear
    end
    it 'populates the training cache' do
      expect(Rails.cache.read('slides')).to be_nil
      VCR.use_cassette 'training/load_from_wiki' do
        subject.load_content
      end
      expect(Rails.cache.read('slides')).not_to be_empty
    end
  end
end
