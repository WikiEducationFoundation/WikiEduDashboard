# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/importers/plagiabot_importer"

describe PlagiabotImporter do
  describe '.check_recent_revisions' do
    it 'should save ithenticate_id for recent suspect revisions' do
      # This is a revision in the plagiabot database, although the date is not
      # 1.day.ago
      create(:revision,
             mw_rev_id: 678763820,
             article_id: 123321,
             date: 1.day.ago)
      create(:article,
             id: 123321,
             namespace: 0)
      stub_request(:get, /tools.wmflabs.org.*/)
        .to_return(body: "[{'project': 'wikipedia', 'page_ns': '0', 'page_title': 'Prasad_karmarkar', 'ithenticate_id': '19201081', 'diff_timestamp': '20150831135151'}]")
      PlagiabotImporter.check_recent_revisions
      rev = Revision.find_by(mw_rev_id: 678763820)
      expect(rev.ithenticate_id).to eq(19201081)
    end
  end

  describe '.api_get_url' do
    it 'returns an ithenticate report url for an ithenticate_id' do
      stub_request(:get, /tools.wmflabs.org.*/)
        .to_return(body: '[https://api.ithenticate.com/view_report/85261B20-0B70-11E7-992A-907D4A89A445]')
      report_url = PlagiabotImporter.api_get_url(ithenticate_id: 19201081)
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
      stub_request(:get, /tools.wmflabs.org.*/).to_return(body: '[;(]')
      report_url = PlagiabotImporter.api_get_url(ithenticate_id: 19201081999)
      expect(report_url).to eq('/not_found')
    end
  end

  describe '.find_recent_plagiarism' do
    it 'should save ithenticate_id for recent suspect revisions' do
      suspected_diffs_array = <<~DIFFS
        [{'lang': 'en', 'page_ns': '0', 'page_title': 'Kai_Hibbard', 'diff_timestamp': '20170318001557', 'ithenticate_id': '27714232', 'project': 'wikipedia', 'diff': '770854173'},
        {'lang': 'en', 'page_ns': '0', 'page_title': 'Bicycle_trainer', 'diff_timestamp': '20170317235741', 'ithenticate_id': '27714172', 'project': 'wikipedia', 'diff': '770851994'},
        {'lang': 'en', 'page_ns': '0', 'page_title': 'Croatian_language', 'diff_timestamp': '20170317235739', 'ithenticate_id': '27714169', 'project': 'wikipedia', 'diff': '770851992'},
        {'lang': 'en', 'page_ns': '0', 'page_title': 'Lauren_Alice_Avery', 'diff_timestamp': '20170317235357', 'ithenticate_id': '27714163', 'project': 'wikipedia', 'diff': '770851591'},
        {'lang': 'en', 'page_ns': '0', 'page_title': 'American_Football_Conference', 'diff_timestamp': '20170317235215', 'ithenticate_id': '27714154', 'project': 'wikipedia', 'diff': '770851416'},
        {'lang': 'en', 'page_ns': '0', 'page_title': 'Shahi_Eid_Gah_Mosque', 'diff_timestamp': '20170317234958', 'ithenticate_id': '27714121', 'project': 'wikipedia', 'diff': '770851175'},
        {'lang': 'en', 'page_ns': '0', 'page_title': 'Flash_(Jay_Garrick)', 'diff_timestamp': '20170317234546', 'ithenticate_id': '27714114', 'project': 'wikipedia', 'diff': '770850689'},
        {'lang': 'en', 'page_ns': '0', 'page_title': 'E-Dubble', 'diff_timestamp': '20170317234214', 'ithenticate_id': '27714088', 'project': 'wikipedia', 'diff': '770850312'},
        {'lang': 'en', 'page_ns': '0', 'page_title': 'Kensington_Cabin', 'diff_timestamp': '20170317231226', 'ithenticate_id': '27713934', 'project': 'wikipedia', 'diff': '770847200'},
        {'lang': 'en', 'page_ns': '0', 'page_title': 'Franklin_Graham', 'diff_timestamp': '20170317230219', 'ithenticate_id': '27713876', 'project': 'wikipedia', 'diff': '770846026'},
        {'lang': 'en', 'page_ns': '0', 'page_title': 'Australian_Senate', 'diff_timestamp': '20170317224839', 'ithenticate_id': '27713806', 'project': 'wikipedia', 'diff': '770844235'},
        {'lang': 'en', 'page_ns': '0', 'page_title': 'Mark_D._Maughmer', 'diff_timestamp': '20170317224424', 'ithenticate_id': '27713782', 'project': 'wikipedia', 'diff': '770843664'},
        {'lang': 'en', 'page_ns': '0', 'page_title': 'HY', 'diff_timestamp': '20170317222521', 'ithenticate_id': '27713642', 'project': 'wikipedia', 'diff': '770841231'},
        {'lang': 'en', 'page_ns': '118', 'page_title': 'EP_Minerals', 'diff_timestamp': '20170317221942', 'ithenticate_id': '27713621', 'project': 'wikipedia', 'diff': '770840488'},
        {'lang': 'en', 'page_ns': '0', 'page_title': 'A_New_Ulster_poetry_magazine', 'diff_timestamp': '20170317221840', 'ithenticate_id': '27713620', 'project': 'wikipedia', 'diff': '770840344'},
        {'lang': 'en', 'page_ns': '0', 'page_title': 'Thomas_Banyacya', 'diff_timestamp': '20170317221453', 'ithenticate_id': '27713586', 'project': 'wikipedia', 'diff': '770839831'},
        {'lang': 'en', 'page_ns': '0', 'page_title': 'Kincardine_Lighthouse', 'diff_timestamp': '20170317220229', 'ithenticate_id': '27713492', 'project': 'wikipedia', 'diff': '770838241'},
        {'lang': 'fr', 'page_ns': '0', 'page_title': 'Le_lieutenant_Mohamed_ZERNOUH.', 'diff_timestamp': '20170317213119', 'ithenticate_id': '27713355', 'project': 'wikipedia', 'diff': '135515669'},
        {'lang': 'fr', 'page_ns': '0', 'page_title': "Histoire_de_l'Alg\xc3\xa9rie", 'diff_timestamp': '20170317211305', 'ithenticate_id': '27713119', 'project': 'wikipedia', 'diff': '135515208'},
        {'lang': 'en', 'page_ns': '0', 'page_title': 'List_of_unsolved_deaths', 'diff_timestamp': '20170317205041', 'ithenticate_id': '27712938', 'project': 'wikipedia', 'diff': '770828204'},
        {'lang': 'en', 'page_ns': '0', 'page_title': 'Scott_Sigman', 'diff_timestamp': '20170317203148', 'ithenticate_id': '27712875', 'project': 'wikipedia', 'diff': '770825815'},
        {'lang': 'en', 'page_ns': '0', 'page_title': 'Huguenot_Burial_Site', 'diff_timestamp': '20170317202721', 'ithenticate_id': '27712812', 'project': 'wikipedia', 'diff': '770825222'},
        {'lang': 'fr', 'page_ns': '0', 'page_title': '\xc3\x89vangile_selon_Matthieu', 'diff_timestamp': '20170317195208', 'ithenticate_id': '27712098', 'project': 'wikipedia', 'diff': '135512653'},
        {'lang': 'en', 'page_ns': '0', 'page_title': 'Triosk', 'diff_timestamp': '20170317195131', 'ithenticate_id': '27712035', 'project': 'wikipedia', 'diff': '770820344'},
        {'lang': 'en', 'page_ns': '0', 'page_title': '1947\xe2\x80\x9348_FC_Barcelona_season', 'diff_timestamp': '20170317193929', 'ithenticate_id': '27711929', 'project': 'wikipedia', 'diff': '770818619'},
        {'lang': 'en', 'page_ns': '0', 'page_title': 'Scott_Sigman', 'diff_timestamp': '20170317193606', 'ithenticate_id': '27711868', 'project': 'wikipedia', 'diff': '770818192'},
        {'lang': 'en', 'page_ns': '0', 'page_title': 'Coat_of_arms_of_the_Czech_Republic', 'diff_timestamp': '20170317192129', 'ithenticate_id': '27711735', 'project': 'wikipedia', 'diff': '770816135'},
        {'lang': 'en', 'page_ns': '0', 'page_title': 'Sleepycat_license', 'diff_timestamp': '20170317191825', 'ithenticate_id': '27711709', 'project': 'wikipedia', 'diff': '770815663'},
        {'lang': 'en', 'page_ns': '0', 'page_title': 'Asim_Saeed_Khan_Manais', 'diff_timestamp': '20170317185010', 'ithenticate_id': '27711433', 'project': 'wikipedia', 'diff': '770811617'},
        {'lang': 'en', 'page_ns': '0', 'page_title': 'Khudabadi_script', 'diff_timestamp': '20170317183719', 'ithenticate_id': '27711255', 'project': 'wikipedia', 'diff': '770809761'},
        {'lang': 'en', 'page_ns': '0', 'page_title': 'Saeed_Ahmed_Khan', 'diff_timestamp': '20170317182847', 'ithenticate_id': '27711157', 'project': 'wikipedia', 'diff': '770808607'},
        {'lang': 'en', 'page_ns': '0', 'page_title': 'Asif_saeed_manais', 'diff_timestamp': '20170317181818', 'ithenticate_id': '27711014', 'project': 'wikipedia', 'diff': '770807136'},
        {'lang': 'en', 'page_ns': '0', 'page_title': '7.62\xc3\x9725mm_Tokarev', 'diff_timestamp': '20170317181319', 'ithenticate_id': '27710960', 'project': 'wikipedia', 'diff': '770806382'},
        {'lang': 'en', 'page_ns': '0', 'page_title': 'List_of_Philippine_television_specials_aired_in_2017', 'diff_timestamp': '20170317180039', 'ithenticate_id': '27710806', 'project': 'wikipedia', 'diff': '770804685'},
        {'lang': 'en', 'page_ns': '0', 'page_title': 'Sleepycat_license', 'diff_timestamp': '20170317175313', 'ithenticate_id': '27710662', 'project': 'wikipedia', 'diff': '770803710'},
        {'lang': 'en', 'page_ns': '0', 'page_title': 'The_Hill_School', 'diff_timestamp': '20170317173338', 'ithenticate_id': '27710413', 'project': 'wikipedia', 'diff': '770800942'},
        {'lang': 'en', 'page_ns': '0', 'page_title': 'Ruby_License', 'diff_timestamp': '20170317173219', 'ithenticate_id': '27710370', 'project': 'wikipedia', 'diff': '770800771'},
        {'lang': 'fr', 'page_ns': '0', 'page_title': 'Al-Thawra_News', 'diff_timestamp': '20170317165405', 'ithenticate_id': '27709827', 'project': 'wikipedia', 'diff': '135507694'},
        {'lang': 'en', 'page_ns': '0', 'page_title': 'Mudragada_Padmanabham', 'diff_timestamp': '20170317163414', 'ithenticate_id': '27709936', 'project': 'wikipedia', 'diff': '770793187'},
        {'lang': 'fr', 'page_ns': '0', 'page_title': 'Ngor_(commune)', 'diff_timestamp': '20170317163410', 'ithenticate_id': '27709565', 'project': 'wikipedia', 'diff': '135506971'},
        {'lang': 'en', 'page_ns': '0', 'page_title': 'Lift_table', 'diff_timestamp': '20170317162243', 'ithenticate_id': '27709452', 'project': 'wikipedia', 'diff': '770791779'},
        {'lang': 'en', 'page_ns': '0', 'page_title': '2018_ICC_World_Twenty20', 'diff_timestamp': '20170317155421', 'ithenticate_id': '27708856', 'project': 'wikipedia', 'diff': '770787858'},
        {'lang': 'en', 'page_ns': '0', 'page_title': '2018_ICC_World_Twenty20', 'diff_timestamp': '20170317155219', 'ithenticate_id': '27708824', 'project': 'wikipedia', 'diff': '770787609'},
        {'lang': 'en', 'page_ns': '0', 'page_title': 'Shape_of_You', 'diff_timestamp': '20170317154447', 'ithenticate_id': '27708694', 'project': 'wikipedia', 'diff': '770786648'},
        {'lang': 'en', 'page_ns': '118', 'page_title': 'About_3Gorillas.com', 'diff_timestamp': '20170317153941', 'ithenticate_id': '27708622', 'project': 'wikipedia', 'diff': '770785959'},
        {'lang': 'en', 'page_ns': '0', 'page_title': 'Israel_Symphony_Orchestra_Rishon_LeZion', 'diff_timestamp': '20170317153655', 'ithenticate_id': '27708607', 'project': 'wikipedia', 'diff': '770785619'},
        {'lang': 'en', 'page_ns': '0', 'page_title': 'Vellum', 'diff_timestamp': '20170317153414', 'ithenticate_id': '27708575', 'project': 'wikipedia', 'diff': '770785292'},
        {'lang': 'en', 'page_ns': '0', 'page_title': 'Fallschirmj\xc3\xa4ger_(World_War_II)', 'diff_timestamp': '20170317152950', 'ithenticate_id': '27708206', 'project': 'wikipedia', 'diff': '770784679'},
        {'lang': 'en', 'page_ns': '0', 'page_title': 'Queens_Gardens,_Brisbane', 'diff_timestamp': '20170317152833', 'ithenticate_id': '27708174', 'project': 'wikipedia', 'diff': '770784503'},
        {'lang': 'en', 'page_ns': '0', 'page_title': 'Wikipeia:Wikiproject_Radiopharmacy/Radiopharmaceuticals', 'diff_timestamp': '20170317152002', 'ithenticate_id': '27707903', 'project': 'wikipedia', 'diff': '770783335'}]
      DIFFS
      stub_request(:get, /tools.wmflabs.org.*/).to_return(body: suspected_diffs_array)

      # This is tricky to test, because we don't know what the recent revisions
      # will be. So, first we have to get one of those revisions.
      suspected_diff = PlagiabotImporter
                       .api_get('suspected_diffs')[0]['diff'].to_i
      create(:revision,
             mw_rev_id: suspected_diff,
             article_id: 1123322,
             date: 1.day.ago)
      create(:article,
             id: 123332,
             namespace: 0)
      PlagiabotImporter.find_recent_plagiarism
      expect(Revision.find_by(mw_rev_id: suspected_diff).ithenticate_id).not_to be_nil
    end

    it 'handles API failures gracefully' do
      stub_request(:any, /.*wmflabs.org.*/).and_raise(JSON::ParserError)
      expect { PlagiabotImporter.find_recent_plagiarism }.not_to raise_error
    end
  end

  describe 'error handling' do
    it 'handles connectivity problems gracefully' do
      stub_request(:any, /.*wmflabs.org.*/).and_raise(Errno::ETIMEDOUT)
      expect(PlagiabotImporter.api_get('suspected_diffs')).to be_empty
    end
  end
end
