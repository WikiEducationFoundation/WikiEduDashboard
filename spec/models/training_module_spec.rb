# frozen_string_literal: true

# == Schema Information
#
# Table name: training_modules
#
#  id            :bigint           not null, primary key
#  name          :string(255)
#  estimated_ttc :string(255)
#  wiki_page     :string(255)
#  slug          :string(255)
#  slide_slugs   :text(65535)
#  description   :text(65535)
#  translations  :text(16777215)
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  kind          :integer          default(0)
#

require 'rails_helper'

describe TrainingModule do
  describe '.load' do
    let(:subject) { described_class.load }

    context 'when there are duplicate slugs' do
      before do
        allow(described_class).to receive(:trim_id_from_filename).and_return(true)
        allow(described_class).to receive(:base_path)
          .and_return(Rails.root.join('spec/support/duplicate_yaml_slugs'))
      end

      it 'raises an error noting the duplicate slug name' do
        expect { subject }.to raise_error(TrainingBase::DuplicateSlugError,
                                          /.*duplicate-yaml-slug.*/)
      end
    end
  end
end
