# frozen_string_literal: true

#= Stubs for various requests
module RequestHelpers
  ##################
  # OAuth requests #
  ##################
  def stub_token_request
    fake_tokens = '{"query":{"tokens":{"csrftoken":"faketoken+\\\\"}}}'
    lang = ENV['wiki_language']
    url = "https://#{lang}.wikipedia.org/w/api.php?action=query&meta=tokens&format=json&type=csrf"
    stub_request(:get, url)
      .to_return(status: 200, body: fake_tokens, headers: {})
  end

  def stub_account_creation_token_request(wiki: nil)
    fake_tokens = '{"query":{"tokens":{"createaccounttoken":"faketoken+\\\\"}}}'
    lang = wiki&.language || ENV['wiki_language']
    params_url = 'action=query&meta=tokens&format=json&type=createaccount'
    url = "https://#{lang}.wikipedia.org/w/api.php?#{params_url}"
    stub_request(:get, url)
      .to_return(status: 200, body: fake_tokens, headers: {})
  end

  def stub_token_request_failure
    token_error = '{"servedby":"mw1135",
      "error": {"code":"mwoauth-invalid-authorization","info":"bar"}}'
    stub_request(:get, /.*wikipedia.*/)
      .to_return(status: 200, body: token_error, headers: {})
  end

  def stub_wikimedia_error(code: 503)
    wikimedia_error = '<!DOCTYPE html><html lang=en><meta charset=utf-8>'\
                      '<title>Wikimedia Error</title></html>'
    stub_request(:get, /.*wikipedia.*/)
      .to_return(status: code, body: wikimedia_error, headers: {})
  end

  def stub_oauth_edit_with_empty_response
    stub_token_request
    stub_request(:post, /.*wikipedia.*/)
      .to_return(status: 200, body: '{}', headers: {})
  end

  def stub_oauth_edit
    # Stub out the posting of content to Wikipedia
    # First the request for edit tokens for a user
    stub_token_request
    # Then the edit request itself
    success = '{"edit":{"result":"Success","pageid":11543696,
              "title":"User:Ragesock","contentmodel":"wikitext",
              "oldrevid":671572777,"newrevid":674946741,
              "newtimestamp":"2015-08-07T05:27:43Z"}}'
    stub_request(:post, /.*wikipedia.*/)
      .to_return(status: 200, body: success, headers: {})
  end

  def stub_account_creation(wiki: nil)
    # Stub out the creation of accounts at Wikipedia
    # First the request for edit tokens for a user
    stub_account_creation_token_request(wiki:)

    # Then the account creation request itself
    success = '{"createaccount":{"status":"PASS", "username":"Ragesock"}}'
    lang = wiki&.language || ENV['wiki_language']
    stub_request(:post, /.*#{lang}.wikipedia.*/)
      .to_return(status: 200, body: success, headers: {})

    # After account creation, stub the query for user info for UserImporter
    stub_list_users_query
  end

  def stub_account_creation_failure_userexists(wiki: nil)
    # Stub out the creation of accounts at Wikipedia
    # First the request for edit tokens for a user
    stub_account_creation_token_request(wiki:)

    # Then the account creation request itself
    failure = '{"createaccount":{"status":"FAIL",
                                 "username":"Ragetest 99", "messagecode": "userexists"}}'
    stub_request(:post, /.*wikipedia.*/)
      .to_return(status: 200, body: failure, headers: {})

    # After account creation, stub the query for user info for UserImporter
    stub_list_users_query
  end

  def stub_account_creation_failure_unexpected(wiki: nil)
    # Stub out the creation of accounts at Wikipedia
    # First the request for edit tokens for a user
    stub_account_creation_token_request(wiki:)

    # Then the account creation request itself
    failure = '{"createaccount":{"username":"Ragetest 99"}}'
    stub_request(:post, /.*wikipedia.*/)
      .to_return(status: 200, body: failure, headers: {})

    # After account creation, stub the query for user info for UserImporter
    stub_list_users_query
  end

  def stub_account_creation_failure_throttle(wiki: nil)
    # Stub out the creation of accounts at Wikipedia
    # First the request for edit tokens for a user
    stub_account_creation_token_request(wiki:)

    # Then the account creation request itself
    failure = '{"createaccount":{"status":"FAIL",
                                 "messagecode":"acct_creation_throttle_hit"}}'
    stub_request(:post, /.*wikipedia.*/)
      .to_return(status: 200, body: failure, headers: {})

    # After account creation, stub the query for user info for UserImporter
    stub_list_users_query
  end

  def stub_account_creation_failure_captcha(wiki: nil)
    # Stub out the creation of accounts at Wikipedia
    # First the request for edit tokens for a user
    stub_account_creation_token_request(wiki:)

    # Then the account creation request itself
    failure = '{"createaccount":{"status":"FAIL",
                                 "messagecode":"captcha-createaccount-fail"}}'
    stub_request(:post, /.*wikipedia.*/)
      .to_return(status: 200, body: failure, headers: {})

    # After account creation, stub the query for user info for UserImporter
    stub_list_users_query
  end

  def stub_oauth_edit_failure
    stub_token_request
    # Then the edit request itself
    failure = '{"servedby":"mw1135", "error":{"code":"protectedpage",
      "info":"The \"templateeditor\" right is required to edit this page",
      "*":"See https://en.wikipedia.org/w/api.php for API usage"}}'
    stub_request(:post, /.*wikipedia.*/)
      .to_return(status: 200, body: failure, headers: {})
  end

  def stub_edit_failure_blocked
    stub_token_request
    failure = '{"servedby":"mw1135", "error":{"code":"blocked",
      "info":"You have been blocked from editing.",
      "*":"See http://en.wikipedia.org/w/api.php for API usage"}}'
    stub_request(:post, /.*wikipedia*/)
      .to_return(status: 200, body: failure, headers: {})
  end

  def stub_edit_failure_autoblocked
    stub_token_request
    failure = '{"servedby":"mw1135", "error":{"code":"autoblocked",
      "info":"Your IP address has been blocked automatically.",
      "*":"See http://en.wikipedia.org/w/api.php for API usage"}}'
    stub_request(:post, /.*wikipedia*/)
      .to_return(status: 200, body: failure, headers: {})
  end

  def stub_oauth_edit_abusefilter
    stub_token_request
    # Then the edit request itself
    failure = '{"edit":{"result":"Failure","code":"abusefilter-warning-email",
              "info":"Hit AbuseFilter: Adding emails in articles",
              "warning":"LOTS OF WARNING TEXT"}}'
    stub_request(:post, /.*wikipedia.*/)
      .to_return(status: 200, body: failure, headers: {})
  end

  # If there's only one instance of a blocked link, MediaWiki returns an array for matches.
  def stub_oauth_edit_spamblock
    stub_token_request
    failure = '{"error":{"code":"spamblacklist",
              "spamblacklist":{"matches":["youtu.be"]}}}'
    stub_request(:post, /.*wikipedia.*/)
      .to_return(status: 200, body: failure, headers: {})
  end

  # If there are multiple links hitting the filter, MediaWiki may return an object of matches.
  def stub_oauth_edit_spamblock_multiple
    stub_token_request
    failure = '{"error":{"code":"spamblacklist",
              "spamblacklist":{"matches":{"0":"ur1.ca","4":"bit.ly/foo"}}}}'
    stub_request(:post, /.*wikipedia.*/)
      .to_return(status: 200, body: failure, headers: {})
  end

  def stub_oauth_edit_captcha
    stub_token_request
    failure = '{"edit":{"result":"Failure","captcha":{"id":1234567,
      "mime":"image/png","type":"image",
      "url":"/w/index.php?title=Special:Captcha/image&wpCaptchaId=1234567"}}}'
    stub_request(:post, /.*wikipedia.*/)
      .to_return(status: 200, body: failure, headers: {})
  end

  def stub_oauth_options_success
    stub_token_request
    success = '{"options":"success"}'
    stub_request(:post, /.*wikipedia.*/)
      .to_return(status: 200, body: success, headers: {})
  end

  def stub_oauth_options_warning
    stub_token_request
    success = '{"warnings":{"options":{"*":"Validation error for \'visualeditor-enable\': not a v'\
              'alid preference"}}, "options":"success"}'
    stub_request(:post, /.*wikipedia.*/)
      .to_return(status: 200, body: success, headers: {})
  end

  ############################
  # MediaWiki query requests #
  ############################
  def stub_contributors_query
    response = String.new '{"continue":{"pccontinue":"2169951|5094","continue":"||"},
                 "query":{"normalized":[{"from":"User_talk:Ragesoss","to":"User talk:Ragesoss"}],
                 "pages":{"2169951":{"pageid":2169951,"ns":3,"title":"User talk:Ragesoss",
                 "anoncontributors":17,"contributors":[{"userid":584,"name":"Danny"}]}}}}'

    stub_request(:get, /.*wikipedia.*/)
      .to_return(status: 200, body: response, headers: {})
  end

  def stub_raw_action
    stub_request(:get, %r{.*wikipedia.org/w/index.php\?action=raw.*})
      .to_return(status: 200, body: String.new('[[wikitext]]'), headers: {})
  end

  def stub_info_query
    stub_request(:get, /.*&prop=info.*/)
      .to_return(status: 200, body: '{}', headers: {})
  end

  def stub_list_users_query
    stub_request(:get, /.*list=users.*/)
      .to_return(status: 200, body: '{"users":[{"emailable":""}]}', headers: {})
  end

  def stub_list_users_query_with_no_email
    stub_request(:get, /.*list=users.*/)
      .to_return(status: 200, body: '{"users":[{}]}', headers: {})
  end

  def stub_wikipedia_503_error
    stub_request(:get, /.*wikipedia.*/)
      .to_return(status: 503, body: '{}', headers: {})
  end

  def stub_commons_503_error
    stub_request(:get, /.*commons.wikimedia.org.*/)
      .to_return(status: 503, body: '', headers: {})
  end

  def stub_wiki_validation
    wikis = [
      'incubator.wikimedia.org',
      'es.wikipedia.org',
      'pt.wikipedia.org',
      'zh.wikipedia.org',
      'mr.wikipedia.org',
      'eu.wikipedia.org',
      'fa.wikipedia.org',
      'fr.wikipedia.org',
      'ru.wikipedia.org',
      'simple.wikipedia.org',
      'tr.wikipedia.org',
      'en.wiktionary.org',
      'es.wiktionary.org',
      'ta.wiktionary.org',
      'es.wikibooks.org',
      'en.wikibooks.org',
      'ar.wikibooks.org',
      'en.wikivoyage.org',
      'wikisource.org',
      'es.wikisource.org',
      'www.wikidata.org',
      'en.wikinews.org',
      'pl.wikiquote.org',
      'de.wikiversity.org',
      'commons.wikimedia.org',
      'de.wikipedia.org',
      'en.wikipedia.org',
      'gl.wikipedia.org',
      'nl.wikipedia.org',
      'sv.wikipedia.org',
      'uk.wikipedia.org'
    ]

    wikis.each do |wiki|
      stub_request(:get, "https://#{wiki}/w/api.php?action=query&format=json&meta=siteinfo")
        .to_return(status: 200,
                   body: "{\"query\":{\"general\":{\"servername\":\"#{wiki}\"}}}",
                   headers: {})
    end
  end

  def stub_block_log_query
    response =
      '{"batchcomplete":"",
        "continue":{"lecontinue":"20180821221509|92647450","continue":"-||"},
        "query":{"logevents":[
          {"logid":92647503,
          "ns":2,
          "title":"User:Verdantpowerinc",
          "pageid":0,
          "logpage":0,
          "params":{"duration":"infinite","flags":["noautoblock"]},
          "type":"block",
          "action":"block",
          "user":"Drmies",
          "timestamp":"2018-08-21T22:19:01Z",
          "comment":"{{uw-softerblock}} <!-- Promotional username, soft block -->"}]}}'

    stub_request(:get, /.*wikipedia.*/)
      .to_return(status: 200, body: response, headers: {})
  end

  def stub_course_response_body
    response =
      '{
      "course": {
        "id": 17794,
        "title": "4A Wikipedia Assignment",
        "description": "Students will edit science articles-primarily physics.
        They will add content, images and references",
        "start": "2024-02-12T00: 00: 00.000Z",
        "end": "2024-06-14T23: 59: 59.000Z",
        "school": "Riverside City College",
        "subject": "Science Communication",
        "slug": "Riverside_City_College/4A_Wikipedia_Assignment_(Spring_2024)",
        "url": "https: //en.wikipedia.org/wiki/Wikipedia:Wiki_Ed/Riverside_City_College
        4A_Wikipedia_Assignment_(Spring_2024)",
        "submitted": true,
        "expected_students": 36,
        "timeline_start": "2024-02-12T00:00:00.000Z",
        "timeline_end": "2024-06-14T23:59:59.000Z",
        "day_exceptions": ",20240219",
        "weekdays": "0101000",
        "no_day_exceptions": false,
        "updated_at": "2024-06-18T21:20:34.000Z",
        "string_prefix": "courses",
        "use_start_and_end_times": false,
        "type": "ClassroomProgramCourse",
        "home_wiki": { "id": 1, "language": "en", "project": "wikipedia" },
        "character_sum": 8225,
        "upload_count": 0,
        "uploads_in_use_count": 0,
        "upload_usages_count": 0,
        "cloned_status": null,
        "flags": {
          "academic_system": null,
          "format": "In-person",
          "timeline_enabled": true,
          "wiki_edits_enabled": true,
          "online_volunteers_enabled": false,
          "disable_student_emails": false,
          "stay_in_sandbox": false,
          "retain_available_articles": true,
          "edit_settings": {
            "wiki_course_page_enabled": true,
            "assignment_edits_enabled": true,
            "enrollment_edits_enabled": true
          },
          "peer_review_count": 1,
          "longest_update": 301,
          "first_update": {
            "enqueued_at": "2023-12-03T15:44:56.633Z",
            "queue_name": "medium_update",
            "queue_latency": 0.007666349411010742
          },
          "update_logs": {
            "14960": {
              "start_time": "2024-06-18T20:35:26.690+00:00",
              "end_time": "2024-06-18T20:35:29.216+00:00",
              "sentry_tag_uuid": "69e140e9-11de-4651-8d19-1d5fcd3b663b",
              "error_count": 0
            }
          },
          "average_update_delay": 300,
          "salesforce_id": "a0fVR000000CwBV",
          "recap_sent_at": "2024-06-15T11:30:04.078Z"
        },
        "level": "Introductory",
        "format": "In-person",
        "private": false,
        "closed?": false,
        "training_library_slug": "students",
        "peer_review_count": 1,
        "needs_update": false,
        "update_until": "2024-07-14T23:59:59.000Z",
        "withdrawn": false,
        "created_at": "2023-12-03T15:22:55.000Z",
        "wikis": [{ "language": "en", "project": "wikipedia" }],
        "namespaces": [],
        "timeline_enabled": true,
        "disable_student_emails": false,
        "academic_system": null,
        "home_wiki_bytes_per_word": 5.175,
        "home_wiki_edits_enabled": true,
        "wiki_edits_enabled": true,
        "assignment_edits_enabled": true,
        "wiki_course_page_enabled": true,
        "enrollment_edits_enabled": true,
        "account_requests_enabled": false,
        "online_volunteers_enabled": false,
        "progress_tracker_enabled": true,
        "stay_in_sandbox": false,
        "no_sandboxes": false,
        "retain_available_articles": true,
        "review_bibliography": false,
        "term": "Spring 2024",
        "legacy": false,
        "ended": true,
        "published": true,
        "closed": false,
        "enroll_url": "https: //dashboard.wikiedu.org/courses/Riverside_City_College
        /4A_Wikipedia_Assignment_(Spring_2024)/enroll/",
        "wiki_string_prefix": "articles",
        "returning_instructor": true,
        "created_count": "0",
        "edited_count": "10",
        "article_count": 10,
        "edit_count": "177",
        "student_count": 36,
        "trained_count": 9,
        "word_count": "1.59K",
        "references_count": "13",
        "view_count": "275K",
        "character_sum_human": "8.23K",
        "updates": {
          "average_delay": 300,
          "last_update": {
            "start_time": "2024-06-18T21:20:31.489+00:00",
            "end_time": "2024-06-18T21:20:34.301+00:00",
            "sentry_tag_uuid": "64ae491f-2e54-4059-880d-b479cc81adac",
            "error_count": 0
          }
        },
        "passcode": "****",
        "canUploadSyllabus": false
      }
    }'

    url = 'https://dashboard.wikiedu.org/courses/Riverside_City_College' \
          '/4A_Wikipedia_Assignment_(Spring_2024)/course.json'
    stub_request(:get, url)
      .to_return(status: 200, body: response, headers: {})
  end

  def stub_categories
    categories_response_body =
      '{
      "course": {
        "categories": [
          {
            "name": "Category 0",
            "depth": 0,
            "source": "Source 0",
            "wiki": {
              "id": 1,
              "language": "en",
              "project": "wikipedia"
            }
          }
        ]
      }
    }'

    url = 'https://dashboard.wikiedu.org/courses/Riverside_City_College' \
          '/4A_Wikipedia_Assignment_(Spring_2024)/categories.json'
    stub_request(:get, url)
      .to_return(status: 200, body: categories_response_body, headers: {})
  end

  def stub_timeline
    timeline_response_body =
      '{
      "course": {
        "weeks": [
          {
            "id": 57366,
            "order": 1,
            "start_date_raw": "2022-01-09T00:00:00.000Z",
            "end_date_raw": "2022-01-15T23:59:59.999Z",
            "start_date": "01/09",
            "end_date": "01/15",
            "title": null,
            "blocks": [
              {
                "id": 127799,
                "kind": 0,
                "content": "Welcome to your Wikipedia assignment course timeline.
                            This page guides you through the steps you will need to
                            complete for your Wikipedia assignment, with links to training
                            modules and your classmates work spaces. Your course has
                            been assigned a Wikipedia Expert. You can reach them
                            through the Get Help button at the top of this page.",
                "week_id": 57366,
                "title": "Introduction to the Wikipedia assignment",
                "order": 1,
                "due_date": null,
                "points": null
              }
            ]
          }
        ]
      }
    }'
    url = 'https://dashboard.wikiedu.org/courses/Riverside_City_College' \
          '/4A_Wikipedia_Assignment_(Spring_2024)/timeline.json'
    stub_request(:get, url)
      .to_return(status: 200, body: timeline_response_body, headers: {})
  end

  def stub_users
    users_response_body =
      '{
      "course": {
        "users": [
          {
            "role": 1,
            "id": 28451264,
            "username": "Joshua Stone"
          },
          {
            "role": 4,
            "id": 22694295,
            "username": "Helaine (Wiki Ed)"
          },
          {
            "role": 0,
            "id": 28515697,
            "username": "CharlieJ385"
          },
          {
            "role": 0,
            "id": 28515751,
            "username": "Diqi Yan"
          }
        ]
      }
    }'

    url = 'https://dashboard.wikiedu.org/courses/Riverside_City_College' \
          '/4A_Wikipedia_Assignment_(Spring_2024)/users.json'
    stub_request(:get, url)
      .to_return(status: 200, body: users_response_body, headers: {})
  end

  def stub_training_modules
    url = 'https://dashboard.wikiedu.org/training_modules.json'
    stub_request(:get, url)
      .to_return(status: 200, body: '{}', headers: {})
  end

  def stub_course
    stub_course_response_body
    stub_categories
    stub_training_modules
    stub_timeline
    stub_users
  end

  def stub_lift_wing_response
    {
      '829840084' => {
        'wp10' => nil,
        'features' => {
          'feature.len(<datasource.wikibase.revision.claim>)' => 3.0,
          'feature.len(<datasource.wikibase.revision.properties>)' => 3.0,
          'feature.len(<datasource.wikibase.revision.aliases>)' => 0.0
        },
        'deleted' => false,
        'prediction' => 'D'
      },
      '829840085' => {
        'wp10' => nil,
        'features' => {
          'feature.len(<datasource.wikibase.revision.claim>)' => 10.0,
          'feature.len(<datasource.wikibase.revision.properties>)' => 9.0,
          'feature.len(<datasource.wikibase.revision.aliases>)' => 1.0
        },
        'deleted' => false,
        'prediction' => 'D'
      }
    }
  end
end
