# frozen_string_literal: true

require 'rails_helper'

describe TrainingModule do
  describe '.load' do
    let(:subject) { described_class.load }

    context 'when there are duplicate slugs' do
      before do
        allow(described_class).to receive(:trim_id_from_filename).and_return(true)
        allow(described_class).to receive(:base_path)
          .and_return("#{Rails.root}/spec/support/duplicate_yaml_slugs")
      end

      it 'raises an error noting the duplicate slug name' do
        expect { subject }.to raise_error(TrainingBase::DuplicateSlugError,
                                          /.*duplicate-yaml-slug.*/)
      end
    end
  end
end
