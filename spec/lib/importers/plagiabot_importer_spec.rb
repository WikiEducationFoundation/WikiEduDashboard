# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/importers/plagiabot_importer"

describe PlagiabotImporter do
  describe '.api_get_url' do
    it 'returns an ithenticate report url for an ithenticate_id' do
      stub_request(:get, /ruby-suspected-plagiarism.toolforge.org.*/)
        .to_return(body: '[https://api.ithenticate.com/view_report/'\
                         '85261B20-0B70-11E7-992A-907D4A89A445]')
      report_url = described_class.api_get_url(ithenticate_id: 19201081)
      url_match = report_url.include?('https://api.ithenticate.com/')
      # plagiabot may have an authentication error with ithenticate, in
      # which case it returns ';-(' as an error message in place of a url.
      # See also: https://github.com/valhallasw/plagiabot/issues/7
      if report_url.include?(';-(')
        puts 'WARNING: plagiabot returned an ithenticate-related error code'
      else
        expect(url_match).to eq(true)
      end
    end

    it 'redirects to a 404 page if no url is available' do
      stub_request(:get, /ruby-suspected-plagiarism.toolforge.org.*/).to_return(body: '[;(]')
      report_url = described_class.api_get_url(ithenticate_id: 19201081999)
      expect(report_url).to eq('/not_found')
    end
  end

  describe '.find_recent_plagiarism' do
    it 'saves ithenticate_id for recent suspect revisions' do
      suspected_diffs_array = <<~DIFFS
        [{"diff_id":414907,"submission_id":"f6baa63f-9456-44da-a6cd-79d31103297d","status_user_text":null,"project":"wikipedia","lang":"fr","page_namespace":0,"page_title":"Abdelkader_Chaou","rev_id":215824986,"rev_parent_id":215774670,"rev_timestamp":"20240610035405","status":0,"status_timestamp":"20240610035503"},
        {"diff_id":414908,"submission_id":"9ec0db67-d01d-4f24-b9ad-93d1749daf87","status_user_text":null,"project":"wikipedia","lang":"es","page_namespace":0,"page_title":"Amanda_Serrano","rev_id":160657665,"rev_parent_id":160657604,"rev_timestamp":"20240610035445","status":0,"status_timestamp":"20240610035504"},
        {"diff_id":414909,"submission_id":"b6541a61-9bbb-4ccc-9aa0-bbbf501454fc","status_user_text":null,"project":"wikipedia","lang":"es","page_namespace":0,"page_title":"Nulificador_Supremo_(cómic)","rev_id":160657773,"rev_parent_id":0,"rev_timestamp":"20240610040724","status":0,"status_timestamp":"20240610040758"},
        {"diff_id":414910,"submission_id":"956888be-00db-4fd1-8953-5768475922b6","status_user_text":null,"project":"wikipedia","lang":"en","page_namespace":0,"page_title":"Curtiss-Wright","rev_id":1228235573,"rev_parent_id":1228234674,"rev_timestamp":"20240610043639","status":0,"status_timestamp":"20240610043802"},
        {"diff_id":414911,"submission_id":"3ac04e74-b1cb-4f32-ba0e-fbe0386fc5f8","status_user_text":"Diannaa","project":"wikipedia","lang":"en","page_namespace":0,"page_title":"Arisaig","rev_id":1228239822,"rev_parent_id":1219072860,"rev_timestamp":"20240610051852","status":2,"status_timestamp":"20240610130003"},
        {"diff_id":414912,"submission_id":"865d5c84-d733-4418-9d33-8389fcd15de3","status_user_text":null,"project":"wikipedia","lang":"en","page_namespace":0,"page_title":"Ode_to_Billie_Joe","rev_id":1228239900,"rev_parent_id":1228174462,"rev_timestamp":"20240610051940","status":0,"status_timestamp":"20240610051958"},
        {"diff_id":414913,"submission_id":"0a447899-67db-4d49-b86a-5d1459de44b3","status_user_text":null,"project":"wikipedia","lang":"en","page_namespace":0,"page_title":"Zionism","rev_id":1228240125,"rev_parent_id":1228237999,"rev_timestamp":"20240610052206","status":0,"status_timestamp":"20240610052238"},
        {"diff_id":414914,"submission_id":"413545a2-dc59-432e-be27-54e5f0055a6a","status_user_text":null,"project":"wikipedia","lang":"en","page_namespace":0,"page_title":"Kirat_Yakthung_Chumlung","rev_id":1228240417,"rev_parent_id":1160380873,"rev_timestamp":"20240610052453","status":0,"status_timestamp":"20240610052542"},
        {"diff_id":414915,"submission_id":"02b0302e-eda8-47a4-a772-082aced0998e","status_user_text":null,"project":"wikipedia","lang":"ar","page_namespace":0,"page_title":"الشحري","rev_id":67100217,"rev_parent_id":67100196,"rev_timestamp":"20240610053228","status":0,"status_timestamp":"20240610053248"},
        {"diff_id":414916,"submission_id":"904be320-a9a8-4fa5-bc78-d4dfc614501a","status_user_text":null,"project":"wikipedia","lang":"es","page_namespace":0,"page_title":"Mercedes-Benz_W31","rev_id":160658721,"rev_parent_id":0,"rev_timestamp":"20240610053415","status":0,"status_timestamp":"20240610053434"},
        {"diff_id":414917,"submission_id":"7a487979-c247-47ea-b642-d74564985203","status_user_text":null,"project":"wikipedia","lang":"en","page_namespace":0,"page_title":"Ode_to_Billie_Joe","rev_id":1228241418,"rev_parent_id":1228241276,"rev_timestamp":"20240610053528","status":0,"status_timestamp":"20240610053553"},
        {"diff_id":414918,"submission_id":"67a1e749-bce9-42ff-ad8f-32f457bfed1f","status_user_text":"Ymblanter","project":"wikipedia","lang":"en","page_namespace":0,"page_title":"Trisomy_X","rev_id":1228241499,"rev_parent_id":1228240335,"rev_timestamp":"20240610053614","status":2,"status_timestamp":"20240610065251"},
        {"diff_id":414919,"submission_id":"940e15d7-572b-4ad6-83ff-ef7291aa7ab1","status_user_text":null,"project":"wikipedia","lang":"ar","page_namespace":0,"page_title":"الشحري","rev_id":67100243,"rev_parent_id":67100237,"rev_timestamp":"20240610054307","status":0,"status_timestamp":"20240610054320"},
        {"diff_id":414920,"submission_id":"16bd35ad-2526-449c-bbdd-24e1fd9dc45d","status_user_text":"Diannaa","project":"wikipedia","lang":"en","page_namespace":0,"page_title":"Alexander_Cameron_(priest)","rev_id":1228243721,"rev_parent_id":1228237204,"rev_timestamp":"20240610055606","status":2,"status_timestamp":"20240610125950"},
        {"diff_id":414921,"submission_id":"413da2e5-0594-405e-bbe0-7c20a5c27dab","status_user_text":null,"project":"wikipedia","lang":"fr","page_namespace":0,"page_title":"Manoir_de_Kerguélavant","rev_id":215826379,"rev_parent_id":0,"rev_timestamp":"20240610060120","status":0,"status_timestamp":"20240610060314"},
        {"diff_id":414922,"submission_id":"5e9795ad-6114-4762-96b1-49fc1d9aa2ef","status_user_text":"CopyPatrolBot","project":"wikipedia","lang":"simple","page_namespace":0,"page_title":"Renmar_Arnejo,","rev_id":9591037,"rev_parent_id":0,"rev_timestamp":"20240610060626","status":1,"status_timestamp":"20240610072518"},
        {"diff_id":414923,"submission_id":"cd716a3b-4503-4b7c-ba56-c5a700a896c4","status_user_text":"CanonNi","project":"wikipedia","lang":"en","page_namespace":0,"page_title":"Pedro_Bernal_Elizalde","rev_id":1228245476,"rev_parent_id":0,"rev_timestamp":"20240610061322","status":1,"status_timestamp":"20240610063134"},
        {"diff_id":414924,"submission_id":"23a7b759-f178-4e11-9fc8-fd29a1b6852a","status_user_text":"Ymblanter","project":"wikipedia","lang":"en","page_namespace":0,"page_title":"Trisomy_X","rev_id":1228248496,"rev_parent_id":1228246142,"rev_timestamp":"20240610064018","status":2,"status_timestamp":"20240610065020"},
        {"diff_id":414925,"submission_id":"a0065758-e8ee-45b2-80b1-898669c296f9","status_user_text":null,"project":"wikipedia","lang":"en","page_namespace":0,"page_title":"Francis_Yeoh","rev_id":1228248790,"rev_parent_id":1228235210,"rev_timestamp":"20240610064306","status":0,"status_timestamp":"20240610064353"},
        {"diff_id":414926,"submission_id":"e31d2b5e-327a-4488-b205-a0840faf1eab","status_user_text":null,"project":"wikipedia","lang":"ar","page_namespace":0,"page_title":"مسجد_الشيخ_لولو","rev_id":67100490,"rev_parent_id":62887116,"rev_timestamp":"20240610065205","status":0,"status_timestamp":"20240610065253"},
        {"diff_id":414927,"submission_id":"2304380f-2f23-4f58-9cfb-51b2fead469c","status_user_text":null,"project":"wikipedia","lang":"ar","page_namespace":0,"page_title":"سوق_القطانين","rev_id":67100521,"rev_parent_id":65975406,"rev_timestamp":"20240610070145","status":0,"status_timestamp":"20240610070215"},
        {"diff_id":414928,"submission_id":"96378a41-e48b-40d6-8641-f5aab3310701","status_user_text":null,"project":"wikipedia","lang":"fr","page_namespace":0,"page_title":"Manoir_de_Saint-Urchaud","rev_id":215827501,"rev_parent_id":0,"rev_timestamp":"20240610070919","status":0,"status_timestamp":"20240610070956"},
        {"diff_id":414929,"submission_id":"751f98e3-181f-4ca6-98d5-479b65652649","status_user_text":null,"project":"wikipedia","lang":"en","page_namespace":0,"page_title":"Barsana","rev_id":1228253221,"rev_parent_id":1216725254,"rev_timestamp":"20240610071135","status":0,"status_timestamp":"20240610071157"},
        {"diff_id":414930,"submission_id":"765ebf1b-0f3d-4e9a-bb2d-2af245e062bb","status_user_text":null,"project":"wikipedia","lang":"en","page_namespace":118,"page_title":"Werner_E_Mosse","rev_id":1228254352,"rev_parent_id":0,"rev_timestamp":"20240610072051","status":0,"status_timestamp":"20240610072130"},
        {"diff_id":414931,"submission_id":"0d844614-cf07-4731-bdc6-4d28da13f31d","status_user_text":null,"project":"wikipedia","lang":"ar","page_namespace":0,"page_title":"أبو_إسلام_أحمد_عبد_الله","rev_id":67100682,"rev_parent_id":67079398,"rev_timestamp":"20240610073025","status":0,"status_timestamp":"20240610073043"},
        {"diff_id":414932,"submission_id":"28385d79-c096-45cb-bc35-556b09858a6e","status_user_text":null,"project":"wikipedia","lang":"ar","page_namespace":0,"page_title":"سوق_خان_السلطان","rev_id":67100695,"rev_parent_id":0,"rev_timestamp":"20240610073412","status":0,"status_timestamp":"20240610073431"},
        {"diff_id":414933,"submission_id":"f539057c-0bf9-4b97-a7db-0b9ef0c1eebe","status_user_text":null,"project":"wikipedia","lang":"es","page_namespace":0,"page_title":"Yoko_Ono","rev_id":160659857,"rev_parent_id":160601234,"rev_timestamp":"20240610073707","status":0,"status_timestamp":"20240610073752"},
        {"diff_id":414934,"submission_id":"7b287736-9975-4ccc-99ae-0e48451403c3","status_user_text":null,"project":"wikipedia","lang":"en","page_namespace":0,"page_title":"War_in_Brda_(1805)","rev_id":1228258050,"rev_parent_id":1228256087,"rev_timestamp":"20240610075409","status":0,"status_timestamp":"20240610082612"},
        {"diff_id":414935,"submission_id":"9f8ccc7b-b7d5-494a-a952-8121163c4d9c","status_user_text":null,"project":"wikipedia","lang":"es","page_namespace":0,"page_title":"Yoko_Ono","rev_id":160660130,"rev_parent_id":160659857,"rev_timestamp":"20240610080326","status":0,"status_timestamp":"20240610080359"},
        {"diff_id":414936,"submission_id":"e1f2c911-559a-4c89-8c7c-803e1056fff8","status_user_text":null,"project":"wikipedia","lang":"en","page_namespace":0,"page_title":"Sitana_spinaecephalus","rev_id":1228260447,"rev_parent_id":1228248492,"rev_timestamp":"20240610081502","status":0,"status_timestamp":"20240610081522"},
        {"diff_id":414937,"submission_id":"239574b6-aeae-4379-815b-f05439639e5c","status_user_text":null,"project":"wikipedia","lang":"es","page_namespace":0,"page_title":"IEEE_802.11ay","rev_id":160660445,"rev_parent_id":0,"rev_timestamp":"20240610084155","status":0,"status_timestamp":"20240610084238"},
        {"diff_id":414938,"submission_id":"342c7a3c-32e5-461b-8644-72eadeaae76b","status_user_text":null,"project":"wikipedia","lang":"fr","page_namespace":0,"page_title":"Manoir_de_Kerguen_(Caudan)","rev_id":215829312,"rev_parent_id":0,"rev_timestamp":"20240610084647","status":0,"status_timestamp":"20240610084732"},
        {"diff_id":414939,"submission_id":"796b33e6-df8e-4dec-b573-ac2942c92105","status_user_text":null,"project":"wikipedia","lang":"es","page_namespace":0,"page_title":"Santurio","rev_id":160660541,"rev_parent_id":156894197,"rev_timestamp":"20240610085207","status":0,"status_timestamp":"20240610085251"},
        {"diff_id":414940,"submission_id":"0be23a7a-6730-4019-90b7-62e4571bfc55","status_user_text":null,"project":"wikipedia","lang":"es","page_namespace":0,"page_title":"Pedrajas","rev_id":160660697,"rev_parent_id":156992058,"rev_timestamp":"20240610090934","status":0,"status_timestamp":"20240610090954"},
        {"diff_id":414941,"submission_id":"268b32f0-35af-4620-bc42-12ca7ea098fe","status_user_text":null,"project":"wikipedia","lang":"ar","page_namespace":0,"page_title":"المجلس_الإسلامي_للإفتاء-الداخل_الفلسطيني48","rev_id":67101185,"rev_parent_id":0,"rev_timestamp":"20240610091501","status":0,"status_timestamp":"20240610091516"},
        {"diff_id":414942,"submission_id":"13d99a68-406e-4381-934f-8198f8ba9060","status_user_text":null,"project":"wikipedia","lang":"es","page_namespace":0,"page_title":"Gyda_Christensen","rev_id":160660880,"rev_parent_id":0,"rev_timestamp":"20240610092429","status":0,"status_timestamp":"20240610092538"},
        {"diff_id":414943,"submission_id":"a8d5673a-d429-4cba-adbc-e567410e30d8","status_user_text":null,"project":"wikipedia","lang":"en","page_namespace":0,"page_title":"Ernest_Bediako_Sampong","rev_id":1228269103,"rev_parent_id":1213649186,"rev_timestamp":"20240610092721","status":0,"status_timestamp":"20240610092746"},
        {"diff_id":414944,"submission_id":"906b499b-e7db-434e-9385-b1aad305095b","status_user_text":"CanonNi","project":"wikipedia","lang":"en","page_namespace":0,"page_title":"Siege_of_Debal","rev_id":1228270591,"rev_parent_id":1227689538,"rev_timestamp":"20240610093948","status":2,"status_timestamp":"20240610112838"},
        {"diff_id":414945,"submission_id":"8728f1d1-3755-41a5-afde-5eb6fba0fa8e","status_user_text":null,"project":"wikipedia","lang":"en","page_namespace":0,"page_title":"Tourism_in_Puducherry","rev_id":1228273780,"rev_parent_id":1228269866,"rev_timestamp":"20240610100526","status":0,"status_timestamp":"20240610100542"},
        {"diff_id":414946,"submission_id":"1fa396aa-e1c4-43bb-906c-8e029b9c5bfb","status_user_text":null,"project":"wikipedia","lang":"es","page_namespace":0,"page_title":"Nomparedes","rev_id":160661326,"rev_parent_id":151278147,"rev_timestamp":"20240610101442","status":0,"status_timestamp":"20240610101538"},
        {"diff_id":414947,"submission_id":"66b0e646-c18c-4df0-9619-05fe65467aca","status_user_text":null,"project":"wikipedia","lang":"en","page_namespace":0,"page_title":"International_Criminal_Court_investigation_in_Palestine","rev_id":1228269941,"rev_parent_id":1227793570,"rev_timestamp":"20240610093418","status":0,"status_timestamp":"20240610101548"},
        {"diff_id":414948,"submission_id":"45c9cab8-6e6c-4daa-a741-66617fecc9f4","status_user_text":null,"project":"wikipedia","lang":"en","page_namespace":118,"page_title":"Philip_Torr","rev_id":1228275092,"rev_parent_id":1225436627,"rev_timestamp":"20240610101702","status":0,"status_timestamp":"20240610101757"},
        {"diff_id":414949,"submission_id":"c34497f9-009c-4870-a442-e896d8687509","status_user_text":null,"project":"wikipedia","lang":"es","page_namespace":0,"page_title":"Primera_Guerra_Mundial","rev_id":160661589,"rev_parent_id":160650009,"rev_timestamp":"20240610103952","status":0,"status_timestamp":"20240610104147"},
        {"diff_id":414950,"submission_id":"cd102861-36c0-43d6-9241-3317b7e14486","status_user_text":null,"project":"wikipedia","lang":"en","page_namespace":0,"page_title":"Cap_d'Agde","rev_id":1228278407,"rev_parent_id":1226880617,"rev_timestamp":"20240610104855","status":0,"status_timestamp":"20240610105053"},
        {"diff_id":414951,"submission_id":"82fcf3b9-62ac-4613-9e65-0a29adcf8e56","status_user_text":"L3X1","project":"wikipedia","lang":"en","page_namespace":0,"page_title":"Leon_Russell","rev_id":1228278556,"rev_parent_id":1228000462,"rev_timestamp":"20240610105025","status":2,"status_timestamp":"20240610152343"},
        {"diff_id":414952,"submission_id":"359affc8-67f1-4fc4-8815-d152d9010c2e","status_user_text":null,"project":"wikipedia","lang":"ar","page_namespace":0,"page_title":"مريم_جعبر","rev_id":67101928,"rev_parent_id":0,"rev_timestamp":"20240610110117","status":0,"status_timestamp":"20240610110152"},
        {"diff_id":414953,"submission_id":"c68f4032-eba4-4cbc-ac10-c1c60dd220e7","status_user_text":null,"project":"wikipedia","lang":"ar","page_namespace":0,"page_title":"الدولة_الأرتقية","rev_id":67101938,"rev_parent_id":67012089,"rev_timestamp":"20240610110406","status":0,"status_timestamp":"20240610110540"},
        {"diff_id":414954,"submission_id":"a7f1173b-d7c8-46d9-a14b-2969ca440a9f","status_user_text":null,"project":"wikipedia","lang":"fr","page_namespace":0,"page_title":"Ordre_du_Mérite_National_(Maroc)","rev_id":215832722,"rev_parent_id":215751353,"rev_timestamp":"20240610111600","status":0,"status_timestamp":"20240610111808"}]
      DIFFS
      stub_request(:get, /.*ruby-suspected-plagiarism.toolforge.org.*/)
        .to_return(body: suspected_diffs_array)

      # This is tricky to test, because we don't know what the recent revisions
      # will be. So, first we have to get one of those revisions.
      # Fourth revision is from en.wiki
      suspected_diff = described_class
                       .api_get('suspected_diffs').fourth['rev_id'].to_i
      create(:revision,
             mw_rev_id: suspected_diff,
             article_id: 1123322,
             date: 1.day.ago)
      create(:article,
             id: 123332,
             namespace: 0)
      described_class.find_recent_plagiarism
      expect(Revision.find_by(mw_rev_id: suspected_diff).ithenticate_id).not_to be_nil
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
