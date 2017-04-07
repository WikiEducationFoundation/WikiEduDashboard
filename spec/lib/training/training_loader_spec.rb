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
    end
    it 'returns an array of training content' do
      VCR.use_cassette 'training/load_from_wiki' do
        slides = subject.load_content
        expect(slides.first.content).not_to be_empty
      end
    end
  end
end
