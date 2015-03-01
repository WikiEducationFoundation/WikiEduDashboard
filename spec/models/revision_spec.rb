require 'rails_helper'

describe Revision do

  describe "revision methods" do
    it "should create Revision objects" do
      revision = build(:revision)
      revision.update
      expect(revision).to be
    end
  end
  
end
