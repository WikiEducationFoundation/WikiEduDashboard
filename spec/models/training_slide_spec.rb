# frozen_string_literal: true
# == Schema Information
#
# Table name: training_slides
#
#  id           :bigint           not null, primary key
#  title        :string(255)
#  title_prefix :string(255)
#  summary      :string(255)
#  button_text  :string(255)
#  wiki_page    :string(255)
#  assessment   :text(16777215)
#  content      :text(65535)
#  translations :text(4294967295)
#  slug         :string(255)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

require 'rails_helper'

describe TrainingSlide do
  describe '.inflate' do
    let(:slug) { 'slide-slug' }
    let(:subject) do
      described_class.inflate({ id: 1, title: 'ohai', slug: }, slug)
    end

    it 'prints an error message if a slide cannot be saved' do
      described_class.create!(id: 1000, title: 'foo', slug:)
      expect(STDOUT).to receive(:puts).with(/#{slug}/)
      expect { subject }.to raise_error ActiveRecord::RecordNotUnique
    end
  end

  it 'does not contain duplicate slide IDs in the .yml source' do
    described_class.destroy_all

    # there should be one TrainingSlide created for reach yaml file.
    # If fewer get created, it means that some were invalid or overwrote another one.
    yaml_file_count = Dir.glob(described_class.path_to_yaml).count
    described_class.load

    expect(described_class.count).to eq(yaml_file_count)
  end
end
