# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/training/training_resource_query_object"

describe TrainingResourceQueryObject do
  before(:all) do
    TrainingModule.load_all
  end

  let(:current_user) { create(:user) }

  describe '#selected_slides_and_excerpt' do
    before do
      TrainingSlide.load
    end

    # The azertyuiop string is supposed not to be present in DB
    it 'returns empty array if not found' do
      expect(query_object('azertyuiop').selected_slides_and_excerpt.size).to eq 0
    end

    # At the time of writing, there are 2 occurences of CNN in DB
    # In content text field in the TrainingSlide object
    it 'returns an array of modules' do
      expect(query_object('cnn').selected_slides_and_excerpt.size).to eq 2
    end

    context 'add some data to test missing modules/lib' do
      before do
        create_some_more_resource_data
      end

      # Because of unmatched resources
      # No lone slide is to be returned as a final result
      # Lone modules are discarded too
      it 'returns only one result out of 3 matches' do
        expect(query_object('postpunk').selected_slides_and_excerpt.size).to eq 1
      end

      it 'returns a complete path for a slide' do
        expect(query_object('postpunk').selected_slides_and_excerpt.first[:path])
          .to eq('my-library/my-other-module/my-third')
      end
    end
  end
end

def query_object(search = nil)
  described_class.new(current_user, search)
end

def create_some_more_resource_data
  # a lone slide without module
  # ie it should not appear in results
  create(:training_slide, id: 100001, title: 'My first',
         slug: 'my-first', content: 'I like Postpunk')
  # this slide belongs to a module that does not belong to any library
  # ie it should not appear in results
  create(:training_slide, id: 100002, title: 'My second',
         slug: 'my-second', content: 'I like Postpunk')
  # a slide that belongs to a module that belongs to a library
  # THIS ONE, we must fetch it
  create(:training_slide, id: 100003, title: 'My third',
         slug: 'my-third', content: 'I like Postpunk')

  # This lone module does not belong to a library
  create(:training_module, slug: 'my-module', slide_slugs: ['my-second'])
  # This module belongs to a library
  create(:training_module, slug: 'my-other-module', slide_slugs: ['my-third'])

  create(:training_library, id: 100001, name: 'My library',
         slug: 'my-library', introduction: 'Intro',
         categories: ['modules' => [{ 'slug' => 'my-other-module' }]])
end
