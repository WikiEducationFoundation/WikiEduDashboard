# frozen_string_literal: true

require 'rails_helper'

describe ApplicationHelper, type: :helper do
  describe '#class_for_path' do
    # class_for_path(req, path)
    subject { class_for_path(req, link_path) }

    let(:req) { OpenStruct.new(path: req_path) }
    let(:link_path) { '/explore' }

    context 'paths are the same' do
      context 'both root path' do
        let(:req_path)  { '/' }
        let(:link_path) { '/' }

        it 'returns `active`' do
          expect(subject).to eq('active')
        end
      end

      context 'exact match' do
        let(:req_path) { link_path }

        it 'returns `active`' do
          expect(subject).to eq('active')
        end
      end

      context 'sub path' do
        let(:req_path) { '/explore/sub-link' }

        it 'returns `active`' do
          expect(subject).to eq('active')
        end
      end

      context 'two sub path links' do
        let(:req_path) { '/explore/sub-link' }
        let(:link_path) { '/explore/sub-link' }

        it 'returns `active` for subpath link' do
          expect(subject).to eq('active')
        end
      end
    end

    context 'paths not the same' do
      let(:req_path) { '/training' }

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end
  end
end
