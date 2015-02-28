require 'rails_helper'

describe Assignment do

  describe "assignment creation" do
    it "should create Assignment objects" do
      assignment = build(:assignment)
      assignment2 = build(:redlink)
      
      expect(assignment.id).to be_kind_of(Integer)
      expect(assignment2.article_id).to be_nil
    end
  end

end
