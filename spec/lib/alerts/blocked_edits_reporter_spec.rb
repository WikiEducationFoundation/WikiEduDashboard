# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/alerts/blocked_edits_reporter"

def mock_mailer
  OpenStruct.new(deliver_now: true)
end

describe BlockedEditsReporter do
  describe '.create_alert' do
    let(:student) { create(:user, username: 'student') }
    let(:student2) { create(:user, username: 'student2') }
    let(:response_data) { {"servedby"=>"mw1229",
                         "error"=>
                          {"info"=>"You have been blocked from editing.",
                           "blockinfo"=>
                            {"blockedtimestamp"=>"2017-09-16T14:1201Z",
                             "blockid"=>7824827,
                             "blockedby"=>"Orangemike",
                             "blockreason"=>
                              "{{uw-softerblock}} <!-- Promotional username, soft block -->",
                             "blockedbyid"=>42464,
                             "blockexpiry"=>"infinite"},
                           "*"=>
                            "See https://en.wikipedia.org/w/api.php for API usage. Subscribe to the mediawiki-api-announce mailing list at &lt;https://lists.wikimedia.org/mailman/listinfo/mediawiki-api-announce&gt; for notice of API deprecations and breaking changes.",
                           "code"=>"blocked"}}
                         }
    it 'creates an Alert record for a blocked edit' do
      BlockedEditsReporter.create_alerts_for_blocked_edits(student, response_data)
      expect(Alert.count).to eq(1)
    end

    it 'does not create multiple alerts' do
      BlockedEditsReporter.create_alerts_for_blocked_edits(student, response_data)
      BlockedEditsReporter.create_alerts_for_blocked_edits(student2, response_data)
      expect(Alert.count).to eq(1)
    end
  end
end
