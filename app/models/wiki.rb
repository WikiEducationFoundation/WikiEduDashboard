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
  has_many :courses_wikis, class_name: 'CoursesWikis'
  has_many :courses, through: :courses_wikis

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

  # One place to look for recently-added languages:
  # https://incubator.wikimedia.org/wiki/Incubator:News
  LANGUAGES = %w[
    aa ab ace ady af ak als alt am ami an ang ar arc ary arz as ast atj av avk ay awa az azb
    ba ban bar bat-smg bbc bcl be be-tarask be-x-old bew bg bh bi bjn blk bm bn bo bpy br bs btm
    bug bxr ca cbk-zam cdo ce ceb ch cho chr chy ckb cmn co commons cr crh cs csb cu
    cv cy da dag de dga din diq dk dsb dtp dty dv dz ee egl el eml en eo epo es et eu ext fa fat
    ff fi fiu-vro fj fo fon fr frp frr fur fy ga gag gan gcr gd gl glk gn gom gor got gpe gsw
    gu guc gur guw gv ha hak haw he hi hif ho hr hsb ht hu hy hyw hz ia id ie ig igl ii ik ilo
    incubator inh io is it iu ja jam jbo jp jv ka kaa kab kcg kbd kbp kg ki kj kk kl km kn ko
    koi kr krc ks ksh ku kus kv kw ky la lad lb lbe lez lfn lg li lij lld lmo ln lo lrc lt
    ltg lv lzh mad mai map-bms mdf meta mg mh mhr mi min minnan mk ml mn mni mnw mo mr mrj ms mt
    mus mwl my myv mzn na nah nan nap nb nds nds-nl ne new ng nia nl nn no nov nqo nrm
    nso nv ny oc olo om or os pa pag pam pap pcd pcm pdc pfl pi pih pl pms pnb pnt ps
    pt pwn qu rm rmy rn ro roa-rup roa-tara ru rue rup rw sa sah sat sc scn sco sd se
    sg sgs sh shi shn shy si simple sk skr sl sm smn sn so sq sr srn ss st stq su sv sw szl
    szy ta tay tcy te tet tg th ti tk tl tly tn to tpi tr trv ts tt tum tw ty tyv udm ug uk
    ur uz ve vec vep vi vls vo vro w wa war wikipedia wo wuu xal xh xmf yi yo yue za
    zea zgh zh zh-cfr zh-classical zh-cn zh-min-nan zh-tw zh-yue zu
  ].freeze
  validates_inclusion_of :language, in: LANGUAGES + [nil]

  MULTILINGUAL_PROJECTS = {
    'wikidata' => 'www.wikidata.org',
    'wikisource' => 'wikisource.org'
  }.freeze

  PROJECTS_NAMESPACES = {
    wikipedia: [0, 2, 4, 6, 10, 12, 14, 118],
    wikibooks: [0, 2, 4, 6, 8, 10, 12, 14, 108, 102, 110],
    wikidata: [0, 2, 4, 6, 8, 10, 12, 14, 146],
    wikimedia: [0, 2, 4, 6, 8, 10, 12, 14],
    wikinews: [0, 2, 4, 6, 8, 10, 12, 14],
    wikiquote: [0, 2, 4, 6, 8, 10, 12, 14],
    wikisource: [0, 2, 4, 6, 8, 10, 12, 14, 100, 102, 104, 106],
    wikiversity: [0, 2, 4, 6, 8, 10, 12, 14, 100, 102, 106],
    wikivoyage: [0, 2, 4, 6, 8, 10, 12, 14],
    wiktionary: [0, 2, 4, 6, 8, 10, 12, 14, 100, 106]
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
    language = language_for_multilingual(language:, project:)
    find_or_create_by(language:, project:)
  end

  def self.language_for_multilingual(language:, project:)
    case project
    when 'wikidata'
      language = nil
    when 'wikisource'
      language = nil if language == 'www'
    when 'wikimedia'
      language = nil unless %w[incubator commons meta].include? language
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
    if project == 'wikipedia'
      "config/templates/#{ENV['dashboard_url']}_#{language}.yml"
    else
      "config/templates/#{ENV['dashboard_url']}_#{language}.#{project}.yml"
    end
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

    raise InvalidWikiError, domain unless PROJECTS.include?(project)
    raise InvalidWikiError, domain unless LANGUAGES.include?(language)
  end

  def ensure_wiki_exists
    return if errors.any? # Skip this check if the wiki had a validation error.
    site_info = WikiApi.new(self).meta(:siteinfo)
    raise InvalidWikiError, domain if site_info.nil?
    servername = site_info.data.dig('general', 'servername')
    raise InvalidWikiError, domain unless base_url == "https://#{servername}"
  end

  class InvalidWikiError < StandardError
    def initialize(domain, msg = 'Invalid Language/Project')
      @msg = msg
      @domain = domain
      super("#{msg}: #{domain}")
    end

    attr_reader :domain
  end
end
