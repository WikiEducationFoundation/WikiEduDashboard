# == Schema Information
#
# Table name: revisions
#
#  id          :integer          not null, primary key
#  characters  :integer          default(0)
#  created_at  :datetime
#  updated_at  :datetime
#  user_id     :integer
#  article_id  :integer
#  views       :integer          default(0)
#  date        :datetime
#  new_article :boolean          default(FALSE)
#  deleted     :boolean          default(FALSE)
#  system      :boolean          default(FALSE)
#

require 'rails_helper'

describe Revision do
  describe '#update' do
    it 'should update a revision with new data' do
      revision = build(:revision,
                       id: 1,
                       article_id: 1,
                       views: 1000)
      revision.update(
        user_id: 1,
        views: 9000)
      expect(revision.views).to eq(9000)
      expect(revision.user_id).to eq(1)
    end
  end

  describe '#url' do
    it 'should generate a diff url for the revision' do
      create(:article,
             id: 1,
             title: 'Vectors_in_gene_therapy')
      create(:revision,
             id: 637221390,
             article_id: 1)
      url = Revision.find(637221390).url
      # rubocop:disable Metrics/LineLength
      expect(url).to eq('https://en.wikipedia.org/w/index.php?title=Vectors_in_gene_therapy&diff=prev&oldid=637221390')
      # rubocop:enable Metrics/LineLength
    end
  end
end
