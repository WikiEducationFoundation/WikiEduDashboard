# frozen_string_literal: true
require 'rails_helper'

describe CopyCourse do
  before do
    wiki_dashboard = 'https://dashboard.wikiedu.org'
    outreach_dashboard = 'https://outreachdashboard.wmflabs.org'
    @selected_dashboard = Features.wiki_ed? ? outreach_dashboard : wiki_dashboard
  end

  let(:url_base) { 'https://dashboard.wikiedu.org/courses/' }
  let(:existent_prod_course_slug) do
    'University_of_South_Carolina/Invertebrate_Zoology_(COPIED_FROM_Spring_2022)'
  end
  let(:course_url) { url_base + existent_prod_course_slug + '/course.json' }
  let(:categories_url) { url_base + existent_prod_course_slug + '/categories.json' }
  let(:users_url) { url_base + existent_prod_course_slug + '/users.json' }
  let(:timeline_url) { url_base + existent_prod_course_slug + '/timeline.json' }
  let(:training_modules_url) { @selected_dashboard + '/training_modules.json' }
  let(:course_response_body) do
    '{
      "course": {
        "id": 15907,
        "slug": "University_of_South_Carolina/Invertebrate_Zoology_(Spring_2022)",
        "school": "University of South Carolina",
        "title": "Invertebrate Zoology",
        "term": "Spring 2022",
        "start": "2022-01-11T00:00:00.000Z",
        "end": "2022-04-30T23:59:59.000Z",
        "type": "ClassroomProgramCourse",
        "home_wiki": {
          "id": 1,
          "language": "en",
          "project": "wikipedia"
        },
        "flags": {
          "update_logs": {
            "28763": {
              "start_time": "2022-05-26T16:13:42.177+00:00",
              "end_time": "2022-05-26T16:13:46.648+00:00",
              "sentry_tag_uuid": "4c0a1b87-da5a-4e82-8f40-3d560690cdb2",
              "error_count": 0
            }
          }
        },
        "wikis": [
          {
            "language": "en",
            "project": "wikipedia"
          }
        ]
      }
    }'
  end
  let(:categories_response_body) do
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
  end
  let(:users_response_body) do
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
  end
  let(:timeline_response_body) do
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
  end

  let(:subject) do
    service = described_class.new(url: url_base + existent_prod_course_slug, user_data: true)
    service.make_copy
  end

  describe '#make_copy' do
    it 'returns an error if /course.json request fails' do
      stub_request(:get, course_url)
        .to_return(status: 404, body: '', headers: {})

      result = subject
      expect(result[:error]).to eq("Error getting data from #{course_url}")
      expect(result[:course]).to be_nil
    end

    it 'returns an error if /categories.json request fails' do
      # Stub the response to the course request
      stub_request(:get, course_url)
        .to_return(status: 200, body: course_response_body, headers: {})
      # Stub the response to the categories request
      stub_request(:get, categories_url)
        .to_return(status: 404, body: '', headers: {})

      result = subject
      expect(result[:error]).to eq("Error getting data from #{categories_url}")
      expect(result[:course]).to be_nil
    end

    it 'returns an error if /users.json request fails' do
      # Stub the response to the course request
      stub_request(:get, course_url)
        .to_return(status: 200, body: course_response_body, headers: {})

      # Stub the response to the categories request
      stub_request(:get, categories_url)
        .to_return(status: 200, body: categories_response_body, headers: {})

      # Stub the response to the users request
      stub_request(:get, users_url)
        .to_return(status: 404, body: '', headers: {})

      result = subject
      expect(result[:error]).to eq("Error getting data from #{users_url}")
      expect(result[:course]).to be_nil
    end

    it 'returns an error if /timeline.json request fails' do
      # Stub the response to the course request
      stub_request(:get, course_url)
        .to_return(status: 200, body: course_response_body, headers: {})

      # Stub the response to the categories request
      stub_request(:get, categories_url)
        .to_return(status: 200, body: categories_response_body, headers: {})

      stub_request(:get, training_modules_url)
        .to_return(status: 200, body: '{}', headers: {})

      # Stub the response to the timeline request
      stub_request(:get, timeline_url)
        .to_return(status: 404, body: timeline_response_body, headers: {})

      # Stub the response to the users request
      stub_request(:get, users_url)
        .to_return(status: 200, body: users_response_body, headers: {})

      result = subject
      expect(result[:error]).to eq("Error getting data from #{timeline_url}")
      expect(result[:course]).to be_nil
    end

    it 'course, categories, and users are created if no error' do
      # Stub the response to the course request
      stub_request(:get, course_url)
        .to_return(status: 200, body: course_response_body, headers: {})

      # Stub the response to the categories request
      stub_request(:get, categories_url)
        .to_return(status: 200, body: categories_response_body, headers: {})

      stub_request(:get, training_modules_url)
        .to_return(status: 200, body: '{}', headers: {})

      # Stub the response to the timeline request
      stub_request(:get, timeline_url)
        .to_return(status: 200, body: timeline_response_body, headers: {})

      # Stub the response to the users request
      stub_request(:get, users_url)
        .to_return(status: 200, body: users_response_body, headers: {})
      result = subject

      # No error was returned
      expect(result[:error]).to be_nil
      # Course returned is not nil
      expect(result[:course]).not_to be_nil

      # The course was created
      expect(Course.exists?(slug: existent_prod_course_slug)).to eq(true)

      # Course users were created
      course = Course.find_by(slug: existent_prod_course_slug)

      expect(course.instructors.length).to eq(1)
      expect(course.instructors.first.username).to eq('Joshua Stone')

      expect(course.staff.length).to eq(1)
      expect(course.staff.first.username).to eq('Helaine (Wiki Ed)')

      expect(course.students.length).to eq(2)
      expect(course.students.first.username).to eq('CharlieJ385')
      expect(course.students.second.username).to eq('Diqi Yan')

      # Wiki exists
      expect(Wiki.exists?(language: 'en', project: 'wikipedia')).to eq(true)

      # Category was created
      expect(Category.exists?(name: 'Category 0', depth: 0, source: 'Source 0',
                              wiki: 1)).to eq(true)

      # Category course was created
      expect(course.categories.length).to eq(1)

      # Users were created
      expect(User.exists?(username: 'Joshua Stone')).to eq(true)
      expect(User.exists?(username: 'Helaine (Wiki Ed)')).to eq(true)
      expect(User.exists?(username: 'CharlieJ385')).to eq(true)
      expect(User.exists?(username: 'Diqi Yan')).to eq(true)

      # Update logs were correctly created
      course.flags['update_logs'].each do |key, _value|
        expect(key).to be_a(Integer)
      end
    end
  end
end
