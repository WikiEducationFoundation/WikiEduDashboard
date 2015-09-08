require 'rails_helper'
require "#{Rails.root}/lib/importers/plagiabot_importer"

describe PlagiabotImporter do
  describe '.check_recent_revisions' do
    it 'should save ithenticate_id for recent suspect revisions' do
      # This is a revision in the plagiabot database, although the date is not
      # 1.day.ago
      create(:revision,
             id: 678763820,
             article_id: 1,
             date: 1.day.ago)
      create(:article,
             id: 1,
             namespace: 0)
      PlagiabotImporter.check_recent_revisions
      expect(Revision.find(678763820).ithenticate_id).to eq(19201081)
    end
  end

  describe '.find_recent_plagiarism' do
    it 'should save ithenticate_id for recent suspect revisions' do
      # This is tricky to test, because we don't know what the recent revisions
      # will be. So, first we have to get one of those revisions.
      suspected_diff = PlagiabotImporter.api_get[0]['diff'].to_i
      expect(suspected_diff.class).to eq(Fixnum)
      create(:revision,
             id: suspected_diff,
             article_id: 1,
             date: 1.day.ago)
      create(:article,
             id: 1,
             namespace: 0)
      PlagiabotImporter.find_recent_plagiarism
      expect(Revision.find(suspected_diff).ithenticate_id).not_to be_nil
    end
  end
end
