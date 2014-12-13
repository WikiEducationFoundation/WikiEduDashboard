require 'spec_helper'

describe Replica do

  describe "API requests" do
    it "should connect to replica tools" do
      response = Replica.connect_to_tool
      response = JSON.parse response
      expect(response["message"]).to eq("You have successfully reached to the WikiEduDashboard tool hosted by the Wikimedia Tool Labs.")
    end
  end

end