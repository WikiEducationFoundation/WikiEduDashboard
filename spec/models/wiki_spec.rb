require 'rails_helper'

describe Wiki, type: :model do
  describe 'validation' do
    let(:wiki) { create(:wiki, language: 'zh', project: 'wiktionary') }
    subject { wiki.valid? }

    let(:bad_language) { create(:wiki, language: 'xx', project: 'wikipedia') }
    it 'does not allow bad language codes' do
      expect { bad_language }.to raise_error(ActiveRecord::RecordInvalid)
    end

    let(:bad_project) { create(:wiki, language: 'en', project: 'wikinothing') }
    it 'does not allow bad projects' do
      expect { bad_project }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end
end
