# frozen_string_literal: true

# == Schema Information
#
# Table name: wikis
#
#  id       :integer          not null, primary key
#  language :string(16)
#  project  :string(16)
#
require_dependency "#{Rails.root}/lib/wiki_api"
require_dependency "#{Rails.root}/lib/word_count"

class Wiki < ApplicationRecord
  has_many :articles
  has_many :assignments
  has_many :revisions
  has_many :courses

  before_validation :ensure_valid_project
  after_validation :ensure_wiki_exists

  # Language / project combination must be unique
  validates_uniqueness_of :project, scope: :language, case_sensitive: false

  PROJECTS = %w[
    wikipedia
    wikibooks
    wikidata
    wikimedia
    wikinews
    wikiquote
    wikisource
    wikiversity
    wikivoyage
    wiktionary
  ].freeze
  validates_inclusion_of :project, in: PROJECTS

  LANGUAGES = %w[
    aa ab ace ady af ak als am an ang ar arc arz as ast atj av ay az azb
    ba ban bar bat-smg bcl be be-tarask be-x-old bg bh bi bjn bm bn bo bpy br bs
    bug bxr ca cbk-zam cdo ce ceb ch cho chr chy ckb cmn co commons cr crh cs csb cu
    cv cy cz da de din diq dk dsb dty dv dz ee egl el eml en eo epo es et eu ext fa
    ff fi fiu-vro fj fo fr frp frr fur fy ga gag gan gd gl glk gn gom gor got gsw
    gu gv ha hak haw he hi hif ho hr hsb ht hu hy hz ia id ie ig ii ik ilo
    incubator inh io is it iu ja jam jbo jp jv ka kaa kab kbd kbp kg ki kj kk kl km kn ko
    koi kr krc ks ksh ku kv kw ky la lad lb lbe lez lfn lg li lij lmo ln lo lrc lt
    ltg lv lzh mai map-bms mdf mg mh mhr mi min minnan mk ml mn mo mr mrj ms mt
    mus mwl my myv mzn na nah nan nap nb nds nds-nl ne new ng nl nn no nov nrm
    nso nv ny oc olo om or os pa pag pam pap pcd pdc pfl pi pih pl pms pnb pnt ps
    pt qu rm rmy rn ro roa-rup roa-tara ru rue rup rw sa sah sat sc scn sco sd se
    sg sgs sh si simple sk sl sm sn so sq sr srn ss st stq su sv sw szl ta tcy te
    tet tg th ti tk tl tn to tpi tr ts tt tum tw ty tyv udm ug uk ur uz ve
    vec vep vi vls vo vro w wa war wikipedia wo wuu xal xh xmf yi yo yue za
    zea zh zh-cfr zh-classical zh-cn zh-min-nan zh-tw zh-yue zu
  ].freeze
  validates_inclusion_of :language, in: LANGUAGES + [nil]

  MULTILINGUAL_PROJECTS = {
    'wikidata' => 'www.wikidata.org',
    'wikisource' => 'wikisource.org'
  }.freeze

  #################
  # Class methods #
  #################

  # This provides fallback values for when a course is created without setting
  # an explicit home wiki language or project
  def self.default_wiki
    get_or_create language: ENV['wiki_language'], project: 'wikipedia'
  end

  def self.get_or_create(language:, project:)
    language = language_for_multilingual(language: language, project: project)
    find_or_create_by(language: language, project: project)
  end

  def self.language_for_multilingual(language:, project:)
    case project
    when 'wikidata'
      language = nil
    when 'wikisource'
      language = nil if language == 'www'
    when 'wikimedia'
      language = nil unless %w[incubator commons].include? language
    end
    language
  end

  ####################
  # Instance methods #
  ####################

  def domain
    if language
      "#{language}.#{project}.org"
    else
      MULTILINGUAL_PROJECTS[project]
    end
  end

  def base_url
    'https://' + domain
  end

  def api_url
    "#{base_url}/w/api.php"
  end

  def edits_enabled?
    ENV["edit_#{domain}"] == 'true'
  end

  def edit_templates
    @templates ||= YAML.load_file(Rails.root + template_file_path)
  end

  def course_prefix
    edit_templates['course_prefix']
  end

  def string_prefix
    case project
    when 'wikipedia'
      'articles'
    when 'wikidata'
      'articles_wikidata'
    else
      'articles_generic'
    end
  end

  def bytes_per_word
    WordCount::BYTES_PER_WORD[domain]
  end

  private

  def template_file_path
    "config/templates/#{ENV['dashboard_url']}_#{language}.yml"
  end

  #############
  # Callbacks #
  #############

  def ensure_valid_project
    # There are two special multilingual projects, which must have language == nil:
    # wikidata, and multilingual wikisource (www.wikisource.org).
    if project == 'wikidata'
      self.language = nil
      return
    end

    if project == 'wikisource' && ['www', nil].include?(language)
      self.language = nil
      return
    end

    raise InvalidWikiError unless PROJECTS.include?(project)
    raise InvalidWikiError unless LANGUAGES.include?(language)
  end

  def ensure_wiki_exists
    return if errors.any? # Skip this check if the wiki had a validation error.
    site_info = WikiApi.new(self).query(meta: :siteinfo)
    raise InvalidWikiError if site_info.nil?
    servername = site_info.data.dig('general', 'servername')
    raise InvalidWikiError unless base_url == "https://#{servername}"
  end

  class InvalidWikiError < StandardError; end
end
