require 'rails_helper'
require "#{Rails.root}/lib/wiki_edits"

describe WikiEdits do
  # We're not testing any of the network stuff, nor whether the requests are
  # well-formatted, but at least this verifies that the flow is parsing tokens
  # in the expected way.
  before do
    stub_oauth_edit

    create(:course,
           id: 1)
    create(:user,
           id: 1,
           wiki_token: 'foo',
           wiki_secret: 'bar')
    create(:user,
           id: 2,
           wiki_token: 'foo',
           wiki_secret: 'bar')
    create(:courses_user,
           course_id: 1,
           user_id: 1)
    create(:courses_user,
           course_id: 1,
           user_id: 2)
  end

  describe '.notify_untrained' do
    it 'should post talk page messages on Wikipedia' do
      WikiEdits.notify_untrained(1, User.first)
    end
  end

  describe '.announce_course' do
    it 'should post to the userpage of the instructor and a noticeboard' do
      WikiEdits.announce_course(Course.first, User.first)
    end
  end

  describe '.enroll_in_course' do
    it 'should post to the userpage of the enrolling student' do
      WikiEdits.enroll_in_course(Course.first, User.first)
    end
  end

  describe '.update_course' do
    it 'should edit a Wikipedia page representing a course' do
      WikiEdits.update_course(Course.first, User.first)
      WikiEdits.update_course(Course.first, User.first, true)
    end
  end

  describe '.notify_users' do
    it 'should post talk page messages on Wikipedia' do
      params = { sectiontitle: 'My message headline',
                 text: 'My message to you',
                 summary: 'My edit summary' }
      WikiEdits.notify_users(User.first, User.all, params)
    end
  end

  describe '.update_assignments' do
    it 'should update talk pages and course page with assignment info' do
      create(:assignment,
             user_id: 1,
             course_id: 1,
             article_title: 'Selfie',
             role: 0)
      WikiEdits.update_assignments(User.first, Course.first, Assignment.all)
      WikiEdits.update_assignments(User.first, Course.first, nil, true)
    end
  end

  describe '.build_assignment_page_content' do
    it 'should add an assignment tag to the wikitext of a page' do
      # https://en.wikipedia.org/w/index.php?title=Talk:Selfie&action=edit&oldid=651330540
      selfie_talk = <<eos
      {{WikiProject Photography|class=B}}
      {{WikiProject Internet culture|class=B|importance=High}}
      {{Online source
      | title = Why Does Every Dude Make That Same Face in Every Photo?
      | author = Troy Patterson
      | year = 2013
      | monthday = 17 April
      | url = http://www.slate.com/articles/life/gentleman_scholar/2013/04/how_to_take_a_selfie_for_men.single.html
      | org = [[Slate (magazine)|Slate]]
      | accessdate = 14 March 2015
      | archiveurl = <!-- url where page was archived, typically on archive.org -->
      | archivedate = <!-- date page was archived; mandatory if archiveurl is used -->
      | section = <!-- section header of Wikipedia:Wikipedia as a press source yyyy page -->
      | wikilink = <!-- link to [[Wikipedia:Wikipedia as a press source yyyy#section header|Wikipedia as a press source yyyy]] -->
      | small = no
      | subject = article
      }}
      {{dyktalk|16 April|2013|entry=... that sociologist Ben Aggers has described the trend of '''[[selfie]]s''' as "the male gaze gone viral"?}}
      {{Old merge full|otherpage=Self-portrait|date=27 August 2014|result=opposed with no support|talk=Talk:Selfie#Merge_to_self-portrait}}
      ==Selca==

      Where is the difference between a selfie and a selca? Is there any? Maybe selca is just the term used in Asia but one thing is for sure, its origin is Korea.<br />
      selca (self capture) -> http://www.8asians.com/2009/05/21/selca-taking-photos-of-yourself-so-you-dont-look-like-a-fool-taking-someone-elses/<br />
      --[[Special:Contributions/212.23.103.78|212.23.103.78]] ([[User talk:212.23.103.78|talk]]) 15:40, 3 September 2013 (UTC)

      == history ==

      *Ah, i had this watchlisted for its eventual creation.  I think it could be improved with additional sources, not just the few which have all been generated since April 1, 2013.  A "history" of the term would also be nice, I may try to help on that.  When I looked a few months ago, it appears the term arose around 2007-08, probably in Britain, as American-born slang words generally don't end with the "-ie" ending that you see in British slang like "telly" for television (surely someone knows what that tendency of form is called?).--'''[[User:Milowent|Milowent]]''' • <small><sup style="position:relative">[[Special:Contributions/Milowent|has]]<span style="position:relative;bottom:-2.0ex;left:-3.2ex;*left:-5.5ex;">[[User talk:Milowent|spoken]]</span></sup></small> 12:55, 6 April 2013 (UTC)
      **Any links you have would be helpful. The best history I've found so far is from Know Your Meme: http://knowyourmeme.com/memes/selfie . That's probably a more reliable source than just about anything else on this topic, anyway. Oddly, there has been an utter explosion of articles about selfies just in the last two weeks or so (and I only found them after I happened to decide to write this article, at just the right time, it seems). Google News search for all of 2012 turns up hardly anything, and the same is true for 2011. The most useful sources I've been about to find so far just happen to all be very recent. --[[User:Ragesoss|ragesoss]] ([[User talk:Ragesoss|talk]]) 13:52, 6 April 2013 (UTC)
      **It's difficult to keep pace with colloquialisms as they develop. I've seen these referred to by posters in the U.S. as selfpics or selfpix as well. I'm not sure how much analysis something like this really needs, but go ahead and document it as best you can. -- [[User:Boteman|Boteman]] ([[User talk:Boteman|talk]]) 03:16, 16 April 2013 (UTC)
      ***I might open it up for expansion and work. The best I can add are some victorian/edwardian examples of these types of photographs and some reasons why they were made. If anyone would like to expound upon that, leading to the huge "selfie" boom of the late 2000s, please, please do so. ([[User:Tsukiakari|Tsukiakari]] ([[User talk:Tsukiakari|talk]]) 00:45, 29 August 2013 (UTC))
      ***please see my post on the first selfie. I really think that we need to foreground that the selfie is a unique phenomenon and that any comparison to previous forms of portraiture (classic or photographic) can be useful to understand formal (use of mirrors etc.) or functional (to convey or create identity) overlap, but they cannot explain away the selfie as a mere remediation of the photographic self-portrait.[[User:Crystal vibes|Crystal vibes]] ([[User talk:Crystal vibes|talk]]) 07:23, 22 September 2014 (UTC)

eos
      create(:assignment,
             id: 1,
             user_id: 3,
             course_id: 10001,
             article_title: 'Selfie',
             role: 0)
      create(:assignment,
             id: 2,
             user_id: 3,
             course_id: 10001,
             article_title: 'Selfie',
             role: 1)
      create(:user,
             id: 3,
             wiki_id: 'Ragesock')
      create(:courses_user,
             user_id: 3,
             course_id: 10001)
      course = create(:course,
                      id: 10001,
                      title: 'Course Title',
                      school: 'School',
                      term: 'Term',
                      slug: 'School/Course_Title_(Term)')
      title = 'Selfie'
      talk_title = 'Talk:Selfie'
      course_page = course.wiki_title
      assignment_titles = WikiEdits.assignments_by_article(course, nil, nil)
      title_assignments = assignment_titles['Selfie']
      assignment_tag = WikiEdits.assignments_tag(course_page, title_assignments)
      page_content = WikiEdits.build_assignment_page_content(assignment_tag,
                                                             course_page,
                                                             selfie_talk)
      expect(page_content).to include("{{dashboard.wikiedu.org assignment | course = ")
      page_content = WikiEdits.build_assignment_page_content(assignment_tag,
                                                             course_page,
                                                             '')
      expect(page_content).to include("{{dashboard.wikiedu.org assignment | course = ")

    end
  end
end
