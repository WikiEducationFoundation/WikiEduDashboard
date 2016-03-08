# == Schema Information
#
# Table name: wikis
#
#  id       :integer          not null, primary key
#  language :string(16)
#  project  :string(16)
#

class Wiki < ActiveRecord::Base
  has_many :articles
  has_many :assignments
  has_many :revisions

  PROJECTS = %w(
    wikibooks
    wikinews
    wikipedia
    wikiquote
    wikisource
    wikiversity
    wikivoyage
    wiktionary
  )
  validates_inclusion_of :project, in: PROJECTS

  LANGUAGES = %w(
    aa ab ace af ak als am an ang ar arc arz as ast av ay az azb
    ba bar bat-smg bcl be be-tarask be-x-old bg bh bi bjn bm bn bo bpy br bs
    bug bxr ca cbk-zam cdo ce ceb ch cho chr chy ckb cmn co cr crh cs csb cu
    cv cy cz da de diq dk dsb dv dz ee egl el eml en eo epo es et eu ext fa
    ff fi fiu-vro fj fo fr frp frr fur fy ga gag gan gd gl glk gn gom got gsw
    gu gv ha hak haw he hi hif ho hr hsb ht hu hy hz ia id ie ig ii ik ilo io
    is it iu ja jbo jp jv ka kaa kab kbd kg ki kj kk kl km kn ko koi kr krc
    ks ksh ku kv kw ky la lad lb lbe lez lg li lij lmo ln lo lrc lt ltg lv
    lzh mai map-bms mdf mg mh mhr mi min minnan mk ml mn mo mr mrj ms mt mus
    mwl my myv mzn na nah nan nap nb nds nds-nl ne new ng nl nn no nov nrm
    nso nv ny oc om or os pa pag pam pap pcd pdc pfl pi pih pl pms pnb pnt ps
    pt qu rm rmy rn ro roa-rup roa-tara ru rue rup rw sa sah sc scn sco sd se
    sg sgs sh si simple sk sl sm sn so sq sr srn ss st stq su sv sw szl ta te
    tet tg th ti tk tl tn to tpi tr ts tt tum tw ty tyv udm ug uk ur uz ve
    vec vep vi vls vo vro w wa war wikipedia wo wuu xal xh xmf yi yo yue za
    zea zh zh-cfr zh-classical zh-cn zh-min-nan zh-tw zh-yue zu
  )
  validates_inclusion_of :language, in: LANGUAGES

  # Is this useful?: has_many :article_wiki, :course_wiki, :user_wiki

  def base_url
    "https://#{language}.#{project}.org"
  end

  def api_url
    "#{base_url}w/api.php"
  end

  # Return the database name for a Wikimedia project wiki.
  # FIXME: Only vaguely correct for most languages.
  def db_name
    short_project = project
    if project == 'wikipedia'
      short_project = 'wiki'
    end
    encoded_language = language.tr('-', '_')
    "#{encoded_language}#{short_project}"
  end

  def self.default_wiki
    # FIXME: Deprecate immediately--this is just a transitional method that allows
    # us to leave some multiwiki support undone in the UI, and the User and Course models.
    get language: ENV['wiki_language'], project: 'wikipedia'
  end

  def self.get(params)
    where(params).first_or_create
  end
end
