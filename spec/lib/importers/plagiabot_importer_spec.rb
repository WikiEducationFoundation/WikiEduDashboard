# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/importers/plagiabot_importer"

describe PlagiabotImporter do
  let(:user) { create(:user) }
  let(:course) { create(:course) }

  before do
    create(:courses_user, course:, user:)
    create(:article, title: 'Assumption_College,_Changanasserry')
  end

  describe '.find_recent_plagiarism' do
    it 'saves ithenticate_id for recent suspect revisions' do
      suspected_diffs_array = <<~DIFFS
        [{"diff_id":441945,"submission_id":"4f71fcfd-29dd-4215-b3de-2a3c0987e3a7","status_user_text":"Ymblanter","project":"wikipedia","lang":"en","page_namespace":0,"page_title":"Conservative_Party_(UK)","rev_id":1260725255,"rev_parent_id":1260127342,"rev_timestamp":"20241202074514","rev_user_text":"Willthorpe","status":2,"status_timestamp":"20241202074638"},
        {"diff_id":441946,"submission_id":"96342545-948b-4af4-b728-b34b8e91ce7a","status_user_text":"1AmNobody24","project":"wikipedia","lang":"en","page_namespace":0,"page_title":"Assumption_College,_Changanasserry","rev_id":1260726925,"rev_parent_id":1260181210,"rev_timestamp":"20241202080450","rev_user_text":"Remjeud","status":1,"status_timestamp":"20241202080643"},
        {"diff_id":441947,"submission_id":"9dbf466b-bc52-4b85-963e-5f3d8cf10842","status_user_text":null,"project":"wikipedia","lang":"es","page_namespace":0,"page_title":"Río_de_Losa","rev_id":163889758,"rev_parent_id":0,"rev_timestamp":"20241202080647","rev_user_text":"Alavense","status":0,"status_timestamp":"20241202080733"},
        {"diff_id":441948,"submission_id":"b9e22f8a-9c7c-4e34-bbeb-d6952ad3496f","status_user_text":"1AmNobody24","project":"wikipedia","lang":"en","page_namespace":0,"page_title":"1883_State_of_the_Union_Address","rev_id":1260728177,"rev_parent_id":0,"rev_timestamp":"20241202081108","rev_user_text":"StateoftheUnionStrong","status":2,"status_timestamp":"20241202084023"},
        {"diff_id":441949,"submission_id":"65ade229-537d-47dc-9fdb-32c4872414b4","status_user_text":"1AmNobody24","project":"wikipedia","lang":"en","page_namespace":0,"page_title":"Ghana_Military_Academy","rev_id":1260728711,"rev_parent_id":1259674334,"rev_timestamp":"20241202081632","rev_user_text":"Akbernard","status":1,"status_timestamp":"20241202083550"},
        {"diff_id":441950,"submission_id":"f0efd165-8694-4b61-9511-cf5b13e1872b","status_user_text":"1AmNobody24","project":"wikipedia","lang":"en","page_namespace":0,"page_title":"The_Nutcracker_Prince","rev_id":1260729217,"rev_parent_id":1260728764,"rev_timestamp":"20241202082441","rev_user_text":"That Article Editing Guy","status":2,"status_timestamp":"20241202082807"},
        {"diff_id":441951,"submission_id":"8982199e-ea0d-48bb-a802-d5b373cfe71f","status_user_text":"CopyPatrolBot","project":"wikipedia","lang":"fr","page_namespace":0,"page_title":"Jean_Roussin","rev_id":220799992,"rev_parent_id":0,"rev_timestamp":"20241202083927","rev_user_text":"2001:4958:27C6:D301:DD06:AEF0:3C0F:FFC3","status":1,"status_timestamp":"20241202091923"},
        {"diff_id":441952,"submission_id":"75cd6a60-f162-416c-a8f2-9f92b49ef79d","status_user_text":null,"project":"wikipedia","lang":"es","page_namespace":0,"page_title":"San_Joaquín_(Iloílo)","rev_id":163890189,"rev_parent_id":0,"rev_timestamp":"20241202085426","rev_user_text":"Alavense","status":0,"status_timestamp":"20241202085500"},
        {"diff_id":441953,"submission_id":"b51fab42-2fa4-40df-bc21-c242475a2619","status_user_text":null,"project":"wikipedia","lang":"fr","page_namespace":0,"page_title":"Les_journées_juridiques_du_patrimoine","rev_id":220800418,"rev_parent_id":220800085,"rev_timestamp":"20241202090310","rev_user_text":"René Dinkel","status":0,"status_timestamp":"20241202090327"},
        {"diff_id":441954,"submission_id":"5f2598ff-057d-4780-bb00-89a6be7a5e7a","status_user_text":null,"project":"wikipedia","lang":"en","page_namespace":0,"page_title":"Beef_and_Dairy_Network_Podcast","rev_id":1260732265,"rev_parent_id":1260724648,"rev_timestamp":"20241202090515","rev_user_text":"Pineapple Storage","status":0,"status_timestamp":"20241202090544"},
        {"diff_id":441955,"submission_id":"c0a11e12-3d11-4611-9237-234282e0af95","status_user_text":"Sphilbrick","project":"wikipedia","lang":"en","page_namespace":0,"page_title":"1886_State_of_the_Union_Address","rev_id":1260733287,"rev_parent_id":0,"rev_timestamp":"20241202091522","rev_user_text":"StateoftheUnionStrong","status":2,"status_timestamp":"20241202132051"},
        {"diff_id":441956,"submission_id":"aa10321e-7ad9-41d2-b076-c7553b1fd060","status_user_text":null,"project":"wikipedia","lang":"fr","page_namespace":0,"page_title":"Djamel_Tatah","rev_id":220800917,"rev_parent_id":217106727,"rev_timestamp":"20241202092541","rev_user_text":"Djamel Tatah","status":0,"status_timestamp":"20241202092605"}]
      DIFFS
      stub_request(:get, /.*ruby-suspected-plagiarism.toolforge.org.*/)
        .to_return(body: suspected_diffs_array)

      # This is tricky to test, because we don't know what the recent revisions
      # will be. So, first we have to get one of those revisions.
      # 2nd revision is from en.wiki

      create(:user, username: 'Remjeud') # User who made the edit

      expect(PossiblePlagiarismAlert.count).to eq(0)
      described_class.find_recent_plagiarism
      expect(PossiblePlagiarismAlert.count).to eq(1)
      new_alert = PossiblePlagiarismAlert.last
      expect(new_alert.details[:submission_id]).to eq('96342545-948b-4af4-b728-b34b8e91ce7a')
      expect(new_alert.article.title).to eq('Assumption_College,_Changanasserry')
      expect(new_alert.wiki.language).to eq('en')

      # Make sure it doesn't make duplicates
      described_class.find_recent_plagiarism
      expect(PossiblePlagiarismAlert.count).to eq(1)
    end

    it 'handles API failures gracefully' do
      stub_request(:any, /.*toolforge.org.*/).and_raise(Oj::ParseError)
      expect { described_class.find_recent_plagiarism }.not_to raise_error
    end
  end

  describe 'error handling' do
    it 'handles connectivity problems gracefully' do
      stub_request(:any, /.*toolforge.org.*/).and_raise(Errno::ETIMEDOUT)
      expect(described_class.api_get('suspected_diffs')).to be_empty
    end
  end
end
