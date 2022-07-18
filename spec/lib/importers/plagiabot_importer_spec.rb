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
        [{"id":303842,"project":"wikipedia","lang":"fr","diff":195408867,"diff_timestamp":"20220718100207","page_title":"Siorac-de-Ribérac","page_ns":0,"ithenticate_id":88005593,"status":"false","status_user":"Community Tech bot","review_timestamp":"2022-07-18T13:54:24.000Z"},
        {"id":303843,"project":"wikipedia","lang":"fr","diff":195408888,"diff_timestamp":"20220718100300","page_title":"Soudat","page_ns":0,"ithenticate_id":88005598,"status":"false","status_user":"Community Tech bot","review_timestamp":"2022-07-18T13:54:24.000Z"},
        {"id":303844,"project":"wikipedia","lang":"fr","diff":195408952,"diff_timestamp":"20220718100534","page_title":"Teyjat","page_ns":0,"ithenticate_id":88005829,"status":"false","status_user":"Community Tech bot","review_timestamp":"2022-07-18T13:54:23.000Z"},
        {"id":303845,"project":"wikipedia","lang":"fr","diff":195408959,"diff_timestamp":"20220718100553","page_title":"Thénac_(Dordogne)","page_ns":0,"ithenticate_id":88005832,"status":"false","status_user":"Community Tech bot","review_timestamp":"2022-07-18T13:54:23.000Z"},
        {"id":303846,"project":"wikipedia","lang":"fr","diff":195409024,"diff_timestamp":"20220718100831","page_title":"Galswinthe","page_ns":0,"ithenticate_id":88005835,"status":"false","status_user":"Bastenbas","review_timestamp":"2022-07-18T14:05:52.000Z"},
        {"id":303847,"project":"wikipedia","lang":"fr","diff":195409089,"diff_timestamp":"20220718101153","page_title":"Tourtoirac","page_ns":0,"ithenticate_id":88005984,"status":"false","status_user":"Community Tech bot","review_timestamp":"2022-07-18T13:54:23.000Z"},
        {"id":303848,"project":"wikipedia","lang":"en","diff":1098970933,"diff_timestamp":"20220718102437","page_title":"Apartheid_South_Africa","page_ns":118,"ithenticate_id":88006634,"status":"false","status_user":"Community Tech bot","review_timestamp":"2022-07-18T10:55:15.000Z"},
        {"id":303849,"project":"wikipedia","lang":"fr","diff":195409365,"diff_timestamp":"20220718102145","page_title":"Villamblard","page_ns":0,"ithenticate_id":88006465,"status":"false","status_user":"Community Tech bot","review_timestamp":"2022-07-18T13:54:22.000Z"},
        {"id":303850,"project":"wikipedia","lang":"fr","diff":195409367,"diff_timestamp":"20220718102154","page_title":"Johann_Christoph_Boecklin","page_ns":0,"ithenticate_id":88006466,"status":"false","status_user":"Bastenbas","review_timestamp":"2022-07-18T14:05:56.000Z"},
        {"id":303851,"project":"wikipedia","lang":"en","diff":1098973230,"diff_timestamp":"20220718104248","page_title":"HamaraBaazar","page_ns":118,"ithenticate_id":88007393,"status":"fixed","status_user":"Sphilbrick","review_timestamp":"2022-07-18T12:39:05.000Z"},
        {"id":303852,"project":"wikipedia","lang":"en","diff":1098973789,"diff_timestamp":"20220718104711","page_title":"2014_African_Sambo_Championships","page_ns":0,"ithenticate_id":88007589,"status":"false","status_user":"Sphilbrick","review_timestamp":"2022-07-18T12:38:29.000Z"},
        {"id":303853,"project":"wikipedia","lang":"en","diff":1098975385,"diff_timestamp":"20220718105933","page_title":"Demography_of_the_Roman_Empire","page_ns":0,"ithenticate_id":88008093,"status":"fixed","status_user":"DanCherek","review_timestamp":"2022-07-18T12:39:51.000Z"},
        {"id":303854,"project":"wikipedia","lang":"en","diff":1098977091,"diff_timestamp":"20220718111128","page_title":"Tilt_(drink)","page_ns":0,"ithenticate_id":88008524,"status":"fixed","status_user":"DanCherek","review_timestamp":"2022-07-18T12:48:47.000Z"},
        {"id":303855,"project":"wikipedia","lang":"en","diff":1098979468,"diff_timestamp":"20220718112703","page_title":"Tomboy","page_ns":0,"ithenticate_id":88009120,"status":"false","status_user":"Sphilbrick","review_timestamp":"2022-07-18T12:36:43.000Z"},
        {"id":303856,"project":"wikipedia","lang":"fr","diff":195410260,"diff_timestamp":"20220718111313","page_title":"Johann_Christoph_Boecklin","page_ns":0,"ithenticate_id":88008948,"status":"false","status_user":"Bastenbas","review_timestamp":"2022-07-18T14:05:58.000Z"},
        {"id":303857,"project":"wikipedia","lang":"en","diff":1098980639,"diff_timestamp":"20220718113610","page_title":"1958_in_the_United_States","page_ns":0,"ithenticate_id":88009515,"status":"false","status_user":"Sphilbrick","review_timestamp":"2022-07-18T12:36:32.000Z"},
        {"id":303858,"project":"wikipedia","lang":"en","diff":1098981620,"diff_timestamp":"20220718114326","page_title":"Andrew_Tate","page_ns":0,"ithenticate_id":88009818,"status":"false","status_user":"Sphilbrick","review_timestamp":"2022-07-18T12:36:23.000Z"},
        {"id":303859,"project":"wikipedia","lang":"en","diff":1098984163,"diff_timestamp":"20220718120333","page_title":"Aimable_Pélissier","page_ns":0,"ithenticate_id":88010624,"status":"fixed","status_user":"Sphilbrick","review_timestamp":"2022-07-18T12:35:40.000Z"},
        {"id":303860,"project":"wikipedia","lang":"en","diff":1098985146,"diff_timestamp":"20220718121226","page_title":"Child_Rights_Network_For_Southern_Africa","page_ns":118,"ithenticate_id":88010990,"status":"fixed","status_user":"Sphilbrick","review_timestamp":"2022-07-18T12:33:51.000Z"},
        {"id":303861,"project":"wikipedia","lang":"en","diff":1098986390,"diff_timestamp":"20220718122242","page_title":"Jose_Moran_Urena","page_ns":118,"ithenticate_id":88011373,"status":"fixed","status_user":"Sphilbrick","review_timestamp":"2022-07-18T12:32:18.000Z"},
        {"id":303862,"project":"wikipedia","lang":"fr","diff":195411893,"diff_timestamp":"20220718121920","page_title":"Cure_(religion)","page_ns":0,"ithenticate_id":88011287,"status":"false","status_user":"Bastenbas","review_timestamp":"2022-07-18T14:08:45.000Z"},
        {"id":303863,"project":"wikipedia","lang":"en","diff":1098988064,"diff_timestamp":"20220718123700","page_title":"William_L_Randall","page_ns":118,"ithenticate_id":88011923,"status":"fixed","status_user":"DanCherek","review_timestamp":"2022-07-18T12:44:23.000Z"},
        {"id":303864,"project":"wikipedia","lang":"es","diff":144836796,"diff_timestamp":"20220718121112","page_title":"Manchita","page_ns":0,"ithenticate_id":88010918,"status":"false","status_user":"LMLM","review_timestamp":"2022-07-18T14:21:10.000Z"},
        {"id":303865,"project":"wikipedia","lang":"fr","diff":195412537,"diff_timestamp":"20220718123807","page_title":"L'Île_au_trésor","page_ns":0,"ithenticate_id":88012075,"status":"false","status_user":"Bastenbas","review_timestamp":"2022-07-18T15:58:20.000Z"},
        {"id":303866,"project":"wikipedia","lang":"fr","diff":195412709,"diff_timestamp":"20220718124515","page_title":"J'ai_la_mémoire_qui_flanche","page_ns":0,"ithenticate_id":88012392,"status":"fixed","status_user":"Bastenbas","review_timestamp":"2022-07-18T16:06:49.000Z"},
        {"id":303867,"project":"wikipedia","lang":"fr","diff":195413024,"diff_timestamp":"20220718125804","page_title":"Histoire_de_la_gestion_des_déchets","page_ns":0,"ithenticate_id":88012820,"status":"false","status_user":"Bastenbas","review_timestamp":"2022-07-18T16:07:51.000Z"},
        {"id":303868,"project":"wikipedia","lang":"es","diff":144836998,"diff_timestamp":"20220718124148","page_title":"Two_for_the_Road_(película)","page_ns":0,"ithenticate_id":88012522,"status":null,"status_user":null,"review_timestamp":null},
        {"id":303869,"project":"wikipedia","lang":"fr","diff":195413608,"diff_timestamp":"20220718132043","page_title":"Pelé","page_ns":0,"ithenticate_id":88013799,"status":"fixed","status_user":"Bastenbas","review_timestamp":"2022-07-18T16:15:06.000Z"},
        {"id":303870,"project":"wikipedia","lang":"es","diff":144837322,"diff_timestamp":"20220718132051","page_title":"Gobierno_de_Salvador_Allende","page_ns":0,"ithenticate_id":88013808,"status":null,"status_user":null,"review_timestamp":null},
        {"id":303871,"project":"wikipedia","lang":"en","diff":1098996440,"diff_timestamp":"20220718134041","page_title":"Torreya_taxifolia","page_ns":0,"ithenticate_id":88014378,"status":"false","status_user":"DanCherek","review_timestamp":"2022-07-18T14:01:10.000Z"},
        {"id":303872,"project":"wikipedia","lang":"en","diff":1098997591,"diff_timestamp":"20220718134841","page_title":"Phoenician_art","page_ns":118,"ithenticate_id":88014629,"status":"false","status_user":"DanCherek","review_timestamp":"2022-07-18T14:00:01.000Z"},
        {"id":303873,"project":"wikipedia","lang":"en","diff":1098998108,"diff_timestamp":"20220718135233","page_title":"American_Research_Center_in_Egypt","page_ns":0,"ithenticate_id":88014805,"status":"fixed","status_user":"DanCherek","review_timestamp":"2022-07-18T14:04:19.000Z"},
        {"id":303874,"project":"wikipedia","lang":"en","diff":1098999169,"diff_timestamp":"20220718140017","page_title":"Urgent_Care_Association","page_ns":0,"ithenticate_id":88015074,"status":"fixed","status_user":"DanCherek","review_timestamp":"2022-07-18T14:05:51.000Z"},
        {"id":303875,"project":"wikipedia","lang":"fr","diff":195414714,"diff_timestamp":"20220718140519","page_title":"École_du_Louvre","page_ns":0,"ithenticate_id":88015337,"status":"false","status_user":"Bastenbas","review_timestamp":"2022-07-18T16:16:02.000Z"},
        {"id":303876,"project":"wikipedia","lang":"fr","diff":195414778,"diff_timestamp":"20220718140727","page_title":"Regards_protestants","page_ns":0,"ithenticate_id":88015340,"status":"fixed","status_user":"Bastenbas","review_timestamp":"2022-07-18T16:24:42.000Z"},
        {"id":303877,"project":"wikipedia","lang":"fr","diff":195414817,"diff_timestamp":"20220718140858","page_title":"Laurent_Courthaliac","page_ns":0,"ithenticate_id":88015582,"status":"fixed","status_user":"Bastenbas","review_timestamp":"2022-07-18T16:39:32.000Z"},
        {"id":303878,"project":"wikipedia","lang":"en","diff":1099007120,"diff_timestamp":"20220718145539","page_title":"Alfred_E._Neuman","page_ns":0,"ithenticate_id":88017321,"status":"fixed","status_user":"DanCherek","review_timestamp":"2022-07-18T15:04:42.000Z"},
        {"id":303879,"project":"wikipedia","lang":"en","diff":1099007818,"diff_timestamp":"20220718150051","page_title":"Wework","page_ns":0,"ithenticate_id":88017461,"status":"fixed","status_user":"DanCherek","review_timestamp":"2022-07-18T15:15:57.000Z"},
        {"id":303880,"project":"wikipedia","lang":"fr","diff":195416313,"diff_timestamp":"20220718150108","page_title":"Tournehem-sur-la-Hem","page_ns":0,"ithenticate_id":88017529,"status":"false","status_user":"Bastenbas","review_timestamp":"2022-07-18T16:40:08.000Z"},
        {"id":303881,"project":"wikipedia","lang":"en","diff":1099009703,"diff_timestamp":"20220718151420","page_title":"James_O'Keefe","page_ns":0,"ithenticate_id":88017895,"status":"false","status_user":"DanCherek","review_timestamp":"2022-07-18T15:20:58.000Z"},
        {"id":303882,"project":"wikipedia","lang":"en","diff":1099011512,"diff_timestamp":"20220718152633","page_title":"Andrew_Lang","page_ns":0,"ithenticate_id":88018281,"status":"fixed","status_user":"DanCherek","review_timestamp":"2022-07-18T15:47:04.000Z"},
        {"id":303883,"project":"wikipedia","lang":"es","diff":144838222,"diff_timestamp":"20220718144529","page_title":"Ambite","page_ns":0,"ithenticate_id":88017719,"status":"fixed","status_user":"LMLM","review_timestamp":"2022-07-18T15:47:12.000Z"},
        {"id":303884,"project":"wikipedia","lang":"es","diff":144838547,"diff_timestamp":"20220718150845","page_title":"Ambite","page_ns":0,"ithenticate_id":88017724,"status":"fixed","status_user":"LMLM","review_timestamp":"2022-07-18T15:47:10.000Z"},
        {"id":303885,"project":"wikipedia","lang":"en","diff":1099013076,"diff_timestamp":"20220718153633","page_title":"Opelika,_Alabama","page_ns":0,"ithenticate_id":88018660,"status":"false","status_user":"DanCherek","review_timestamp":"2022-07-18T15:43:42.000Z"},
        {"id":303886,"project":"wikipedia","lang":"en","diff":1099013367,"diff_timestamp":"20220718153818","page_title":"Riva_San_Vitale","page_ns":0,"ithenticate_id":88018731,"status":"false","status_user":"DanCherek","review_timestamp":"2022-07-18T15:49:36.000Z"},
        {"id":303887,"project":"wikipedia","lang":"en","diff":1099014012,"diff_timestamp":"20220718154218","page_title":"179th_Field_Regiment,_Royal_Artillery","page_ns":0,"ithenticate_id":88018846,"status":"false","status_user":"DanCherek","review_timestamp":"2022-07-18T15:52:01.000Z"},
        {"id":303888,"project":"wikipedia","lang":"fr","diff":195417036,"diff_timestamp":"20220718152855","page_title":"Hocquinghen","page_ns":0,"ithenticate_id":88018568,"status":"false","status_user":"Bastenbas","review_timestamp":"2022-07-18T16:40:10.000Z"},
        {"id":303889,"project":"wikipedia","lang":"fr","diff":195417071,"diff_timestamp":"20220718153019","page_title":"Licques","page_ns":0,"ithenticate_id":88018571,"status":"false","status_user":"Bastenbas","review_timestamp":"2022-07-18T16:40:11.000Z"},
        {"id":303890,"project":"wikipedia","lang":"en","diff":1099017219,"diff_timestamp":"20220718160353","page_title":"Ford_Power_Stroke_engine","page_ns":0,"ithenticate_id":88019496,"status":null,"status_user":null,"review_timestamp":null},
        {"id":303891,"project":"wikipedia","lang":"en","diff":1099017530,"diff_timestamp":"20220718160558","page_title":"Riva_San_Vitale","page_ns":0,"ithenticate_id":88019572,"status":"false","status_user":"DanCherek","review_timestamp":"2022-07-18T16:18:47.000Z"},
        {"id":303892,"project":"wikipedia","lang":"en","diff":1099018093,"diff_timestamp":"20220718160909","page_title":"Influence_of_Madonna_with_sexuality","page_ns":0,"ithenticate_id":88019681,"status":null,"status_user":null,"review_timestamp":null},
        {"id":303893,"project":"wikipedia","lang":"fr","diff":195418377,"diff_timestamp":"20220718161442","page_title":"Bainghen","page_ns":0,"ithenticate_id":88019821,"status":"false","status_user":"Bastenbas","review_timestamp":"2022-07-18T16:41:07.000Z"},
        {"id":303894,"project":"wikipedia","lang":"en","diff":1099020871,"diff_timestamp":"20220718162745","page_title":"Dhund_(tribe)","page_ns":0,"ithenticate_id":88020218,"status":"fixed","status_user":"Sphilbrick","review_timestamp":"2022-07-18T17:10:13.000Z"},
        {"id":303895,"project":"wikipedia","lang":"es","diff":144839589,"diff_timestamp":"20220718162351","page_title":"Cuenca_del_río_Petorca","page_ns":0,"ithenticate_id":88020201,"status":null,"status_user":null,"review_timestamp":null},
        {"id":303896,"project":"wikipedia","lang":"es","diff":144839804,"diff_timestamp":"20220718163659","page_title":"Ataques_escolares_en_China","page_ns":0,"ithenticate_id":88020492,"status":null,"status_user":null,"review_timestamp":null},
        {"id":303897,"project":"wikipedia","lang":"es","diff":144839934,"diff_timestamp":"20220718164533","page_title":"Ataques_escolares_en_China","page_ns":0,"ithenticate_id":88020629,"status":null,"status_user":null,"review_timestamp":null},
        {"id":303898,"project":"wikipedia","lang":"fr","diff":195419201,"diff_timestamp":"20220718164438","page_title":"Chant","page_ns":0,"ithenticate_id":88020667,"status":"false","status_user":"Bastenbas","review_timestamp":"2022-07-18T18:16:29.000Z"},
        {"id":303899,"project":"wikipedia","lang":"es","diff":144840196,"diff_timestamp":"20220718170149","page_title":"Razón_de_Estado","page_ns":0,"ithenticate_id":88021069,"status":null,"status_user":null,"review_timestamp":null},
        {"id":303900,"project":"wikipedia","lang":"fr","diff":195419308,"diff_timestamp":"20220718164908","page_title":"Marathon_féminin_aux_championnats_du_monde_d'athlétisme_2022","page_ns":0,"ithenticate_id":88020947,"status":"false","status_user":"Bastenbas","review_timestamp":"2022-07-18T18:16:43.000Z"},
        {"id":303901,"project":"wikipedia","lang":"en","diff":1099026498,"diff_timestamp":"20220718170412","page_title":"Feeding_Laramie_Valley","page_ns":118,"ithenticate_id":88021166,"status":null,"status_user":null,"review_timestamp":null},
        {"id":303902,"project":"wikipedia","lang":"fr","diff":195419943,"diff_timestamp":"20220718171800","page_title":"Christiane_Brunet","page_ns":0,"ithenticate_id":88021510,"status":"false","status_user":"Community Tech bot","review_timestamp":"2022-07-18T18:16:12.000Z"},
        {"id":303903,"project":"wikipedia","lang":"es","diff":144840602,"diff_timestamp":"20220718172831","page_title":"Asiento_de_la_aerolínea","page_ns":0,"ithenticate_id":88021822,"status":null,"status_user":null,"review_timestamp":null},
        {"id":303904,"project":"wikipedia","lang":"en","diff":1099033846,"diff_timestamp":"20220718174926","page_title":"Sarah_of_the_Desert","page_ns":0,"ithenticate_id":88022302,"status":null,"status_user":null,"review_timestamp":null},
        {"id":303905,"project":"wikipedia","lang":"fr","diff":195420635,"diff_timestamp":"20220718174941","page_title":"Domenico_Diodati","page_ns":0,"ithenticate_id":88022370,"status":"false","status_user":"Bastenbas","review_timestamp":"2022-07-18T18:16:46.000Z"},
        {"id":303906,"project":"wikipedia","lang":"en","diff":1099036913,"diff_timestamp":"20220718180636","page_title":"New_York_State_Youth_Leadership_Council","page_ns":118,"ithenticate_id":88022634,"status":"false","status_user":"Community Tech bot","review_timestamp":"2022-07-18T18:46:09.000Z"},
        {"id":303907,"project":"wikipedia","lang":"en","diff":1099037229,"diff_timestamp":"20220718180810","page_title":"Transnational_Government_of_Tamil_Eelam","page_ns":0,"ithenticate_id":88022683,"status":null,"status_user":null,"review_timestamp":null},
        {"id":303908,"project":"wikipedia","lang":"en","diff":1099037744,"diff_timestamp":"20220718181131","page_title":"Embraer_C-390_Millennium","page_ns":0,"ithenticate_id":88022730,"status":"false","status_user":"Sphilbrick","review_timestamp":"2022-07-18T20:07:58.000Z"},
        {"id":303909,"project":"wikipedia","lang":"en","diff":1099038242,"diff_timestamp":"20220718181441","page_title":"Transnational_Government_of_Tamil_Eelam","page_ns":0,"ithenticate_id":88022751,"status":null,"status_user":null,"review_timestamp":null},
        {"id":303910,"project":"wikipedia","lang":"es","diff":144841429,"diff_timestamp":"20220718181222","page_title":"Acción_del_10_de_diciembre_de_1800","page_ns":0,"ithenticate_id":88022828,"status":null,"status_user":null,"review_timestamp":null},
        {"id":303911,"project":"wikipedia","lang":"fr","diff":195420955,"diff_timestamp":"20220718180034","page_title":"Malek_Hamza","page_ns":0,"ithenticate_id":88022620,"status":null,"status_user":null,"review_timestamp":null},
        {"id":303912,"project":"wikipedia","lang":"en","diff":1099042888,"diff_timestamp":"20220718184059","page_title":"Borders_Group","page_ns":0,"ithenticate_id":88023239,"status":"false","status_user":"DanCherek","review_timestamp":"2022-07-18T21:14:19.000Z"},
        {"id":303913,"project":"wikipedia","lang":"en","diff":1099043822,"diff_timestamp":"20220718184624","page_title":"Ozrinići_(tribe)","page_ns":0,"ithenticate_id":88023350,"status":null,"status_user":null,"review_timestamp":null},
        {"id":303914,"project":"wikipedia","lang":"es","diff":144841857,"diff_timestamp":"20220718183502","page_title":"La_Cenicienta_(película_de_2015)","page_ns":0,"ithenticate_id":88023226,"status":null,"status_user":null,"review_timestamp":null},
        {"id":303915,"project":"wikipedia","lang":"es","diff":144841943,"diff_timestamp":"20220718183954","page_title":"Delegado_presidencial_regional_de_Chile","page_ns":0,"ithenticate_id":88023228,"status":null,"status_user":null,"review_timestamp":null},
        {"id":303916,"project":"wikipedia","lang":"en","diff":1099045196,"diff_timestamp":"20220718185431","page_title":"Chocolate","page_ns":0,"ithenticate_id":88023500,"status":"false","status_user":"DanCherek","review_timestamp":"2022-07-18T21:15:31.000Z"},
        {"id":303917,"project":"wikipedia","lang":"en","diff":1099045222,"diff_timestamp":"20220718185444","page_title":"Cherry_Bekaert","page_ns":0,"ithenticate_id":88023502,"status":null,"status_user":null,"review_timestamp":null},
        {"id":303918,"project":"wikipedia","lang":"en","diff":1099045340,"diff_timestamp":"20220718185528","page_title":"Richard_S._Ostfeld","page_ns":118,"ithenticate_id":88023532,"status":null,"status_user":null,"review_timestamp":null},
        {"id":303919,"project":"wikipedia","lang":"es","diff":144842061,"diff_timestamp":"20220718184607","page_title":"Delegado_presidencial_regional_de_Chile","page_ns":0,"ithenticate_id":88023443,"status":null,"status_user":null,"review_timestamp":null},
        {"id":303920,"project":"wikipedia","lang":"es","diff":144842132,"diff_timestamp":"20220718185038","page_title":"Delegado_presidencial_regional_de_Chile","page_ns":0,"ithenticate_id":88023446,"status":null,"status_user":null,"review_timestamp":null},
        {"id":303921,"project":"wikipedia","lang":"en","diff":1099047634,"diff_timestamp":"20220718191000","page_title":"Michael_Hudson_(economist)","page_ns":0,"ithenticate_id":88023811,"status":"fixed","status_user":"DanCherek","review_timestamp":"2022-07-18T21:13:36.000Z"},
        {"id":303922,"project":"wikipedia","lang":"es","diff":144842312,"diff_timestamp":"20220718185939","page_title":"Delegado_presidencial_provincial_de_Chile","page_ns":0,"ithenticate_id":88023663,"status":null,"status_user":null,"review_timestamp":null},
        {"id":303923,"project":"wikipedia","lang":"en","diff":1099047943,"diff_timestamp":"20220718191203","page_title":"Michael_Hudson_(economist)","page_ns":0,"ithenticate_id":88023873,"status":"fixed","status_user":"DanCherek","review_timestamp":"2022-07-18T21:13:36.000Z"},
        {"id":303924,"project":"wikipedia","lang":"en","diff":1099048266,"diff_timestamp":"20220718191408","page_title":"Found_Sound_Nation","page_ns":0,"ithenticate_id":88023880,"status":null,"status_user":null,"review_timestamp":null},
        {"id":303925,"project":"wikipedia","lang":"en","diff":1099048989,"diff_timestamp":"20220718191842","page_title":"2022_monkeypox_outbreak_in_the_United_States","page_ns":0,"ithenticate_id":88023922,"status":"fixed","status_user":"DanCherek","review_timestamp":"2022-07-18T21:11:50.000Z"},
        {"id":303926,"project":"wikipedia","lang":"fr","diff":195422338,"diff_timestamp":"20220718192158","page_title":"Caffiers","page_ns":0,"ithenticate_id":88023980,"status":null,"status_user":null,"review_timestamp":null},
        {"id":303927,"project":"wikipedia","lang":"en","diff":1099053029,"diff_timestamp":"20220718194124","page_title":"Market_Watch","page_ns":118,"ithenticate_id":88024328,"status":"fixed","status_user":"DanCherek","review_timestamp":"2022-07-18T21:09:48.000Z"},
        {"id":303928,"project":"wikipedia","lang":"fr","diff":195422655,"diff_timestamp":"20220718194039","page_title":"Guînes","page_ns":0,"ithenticate_id":88024290,"status":null,"status_user":null,"review_timestamp":null},
        {"id":303929,"project":"wikipedia","lang":"en","diff":1099055321,"diff_timestamp":"20220718195443","page_title":"Subaru_BRAT","page_ns":0,"ithenticate_id":88024573,"status":null,"status_user":null,"review_timestamp":null},
        {"id":303930,"project":"wikipedia","lang":"en","diff":1099055888,"diff_timestamp":"20220718195803","page_title":"German_Women's_Curling_Championship","page_ns":0,"ithenticate_id":88024649,"status":"false","status_user":"Sphilbrick","review_timestamp":"2022-07-18T20:07:07.000Z"},
        {"id":303931,"project":"wikipedia","lang":"en","diff":1099056450,"diff_timestamp":"20220718200118","page_title":"Hallo_(film)","page_ns":0,"ithenticate_id":88024741,"status":null,"status_user":null,"review_timestamp":null},
        {"id":303932,"project":"wikipedia","lang":"en","diff":1099059555,"diff_timestamp":"20220718201929","page_title":"Sam_Smith_(English_sculptor)","page_ns":0,"ithenticate_id":88024996,"status":"fixed","status_user":"Diannaa","review_timestamp":"2022-07-18T20:32:08.000Z"},
        {"id":303933,"project":"wikipedia","lang":"es","diff":144843606,"diff_timestamp":"20220718201547","page_title":"Sartén","page_ns":0,"ithenticate_id":88025008,"status":null,"status_user":null,"review_timestamp":null},
        {"id":303934,"project":"wikipedia","lang":"en","diff":1099061130,"diff_timestamp":"20220718202844","page_title":"Henry_V._Jardine","page_ns":0,"ithenticate_id":88025640,"status":null,"status_user":null,"review_timestamp":null},
        {"id":303935,"project":"wikipedia","lang":"es","diff":144843774,"diff_timestamp":"20220718202427","page_title":"Soy_Luna","page_ns":0,"ithenticate_id":88025624,"status":null,"status_user":null,"review_timestamp":null},
        {"id":303936,"project":"wikipedia","lang":"en","diff":1099065372,"diff_timestamp":"20220718205406","page_title":"Small_Axe_Project","page_ns":0,"ithenticate_id":88026096,"status":null,"status_user":null,"review_timestamp":null},
        {"id":303937,"project":"wikipedia","lang":"en","diff":1099065394,"diff_timestamp":"20220718205415","page_title":"NachoNacho","page_ns":118,"ithenticate_id":88026098,"status":"false","status_user":"Community Tech bot","review_timestamp":"2022-07-18T21:04:49.000Z"},
        {"id":303938,"project":"wikipedia","lang":"fr","diff":195424080,"diff_timestamp":"20220718204549","page_title":"Renée_Gagnon","page_ns":0,"ithenticate_id":88025956,"status":null,"status_user":null,"review_timestamp":null},
        {"id":303939,"project":"wikipedia","lang":"en","diff":1099066166,"diff_timestamp":"20220718205853","page_title":"Bibliography_of_Ukrainian_history","page_ns":0,"ithenticate_id":88026176,"status":"false","status_user":"DanCherek","review_timestamp":"2022-07-18T21:12:24.000Z"},
        {"id":303940,"project":"wikipedia","lang":"en","diff":1099066667,"diff_timestamp":"20220718210158","page_title":"Love_Island_(2015_TV_series,_series_8)","page_ns":0,"ithenticate_id":88026243,"status":null,"status_user":null,"review_timestamp":null},
        {"id":303941,"project":"wikipedia","lang":"en","diff":1099069146,"diff_timestamp":"20220718211659","page_title":"Meriones_(mythology)","page_ns":0,"ithenticate_id":88026429,"status":null,"status_user":null,"review_timestamp":null}]
      DIFFS
      stub_request(:get, /.*ruby-suspected-plagiarism.toolforge.org.*/)
        .to_return(body: suspected_diffs_array)

      # This is tricky to test, because we don't know what the recent revisions
      # will be. So, first we have to get one of those revisions.
      suspected_diff = described_class
                       .api_get('suspected_diffs').last['diff'].to_i
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
