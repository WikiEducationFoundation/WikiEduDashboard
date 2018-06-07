# frozen_string_literal: true
# == Schema Information
#
# Table name: training_slides
#
#  id           :bigint(8)        not null, primary key
#  title        :string(255)
#  title_prefix :string(255)
#  summary      :string(255)
#  button_text  :string(255)
#  wiki_page    :string(255)
#  assessment   :text(65535)
#  content      :text(65535)
#  translations :text(16777215)
#  slug         :string(255)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

require 'rails_helper'

describe TrainingSlide do
  describe '.inflate' do
    let(:slug) { 'slide-slug' }
    let(:subject) do
      described_class.inflate({ id: 1, title: 'ohai', slug: slug }, slug)
    end

    it 'prints an error message if a slide cannot be saved' do
      TrainingSlide.create!(id: 1000, title: 'foo', slug: slug)
      expect(STDOUT).to receive(:puts).with(/#{slug}/)
      expect { subject }.to raise_error ActiveRecord::RecordNotUnique
    end
  end
end
