require 'rails_helper'

describe Replica do

  describe "API requests" do
    # it "should connect to replica tools" do
    #   response = Replica.connect_to_tool
    #   expect(response).to eq("You have successfully reached to the WikiEduDashboard tool hosted by the Wikimedia Tool Labs.")
    # end

    # it "should return data for all revisions made by a certain user" do
    #   pending("Awaiting implementation")
    # end

    # it "should return data for all revisions made by a collection of users" do
    #   pending("Awaiting implementation")
    # end

    # it "should return data for an article with a given id" do
    #   pending("Awaiting implementation")
    # end

    # it "should return data for articles edited by a user" do
    #   response = Replica.get_articles_edited_by_user('Ragesoss')
    #   expect(response).to_not be_empty
    # end

    # it "should return data for articles edited by a class" do
    #   response = Replica.get_articles_edited_by_class(366)
    #   expect(response).to_not be_empty
    # end

    it "should return data for articles edited this term" do
      VCR.use_cassette "replica/articles" do
        all_users = [
          { 'wiki_id' => 'ELE427' },
          { 'wiki_id' => 'Kcmpayne' },
          { 'wiki_id' => 'Mrbauer1234' },
          { 'wiki_id' => 'Azul97' }
        ]
        all_users.each_with_index do |u, i|
          all_users[i] = OpenStruct.new u
        end
        response = Replica.get_articles_edited_this_term_by_users(all_users)
        expect(response.count).to eq(4)
      end
    end

    it "should return revisions from this term" do
      VCR.use_cassette "replica/revisions" do
        all_users = [
          { 'wiki_id' => 'ELE427' },
          { 'wiki_id' => 'Kcmpayne' },
          { 'wiki_id' => 'Mrbauer1234' },
          { 'wiki_id' => 'Azul97' }
        ]
        all_users.each_with_index do |u, i|
          all_users[i] = OpenStruct.new u
        end
        response = Replica.get_revisions_this_term_by_users(all_users)
        expect(response.count).to eq(42)
      end
    end
  end

  # describe "API response parsing" do
  #   it "should return the number of characters from a certain revision" do
  #     pending("Awaiting implementation")
  #   end
  # end

end