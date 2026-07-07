# frozen_string_literal: true

require 'rails_helper'

describe SystemStatsController, type: :request do
  let(:admin) { create(:admin) }
  let(:user) { create(:user) }

  describe '#index' do
    context 'when user is not signed in' do
      it 'redirects or returns 401/302' do
        get '/system_stats'
        expect(response.status).to eq(302).or eq(401)
      end
    end

    context 'when user is not an admin' do
      before do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
      end

      it 'returns 302 or 401' do
        get '/system_stats'
        expect(response.status).to eq(302).or eq(401)
      end
    end

    context 'when user is an admin' do
      before do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(admin)
      end

      it 'renders 200 for HTML format' do
        get '/system_stats'
        expect(response.status).to eq(200)
      end

      it 'returns JSON with expected structure' do
        create(:system_stat, snapshot_date: Time.zone.today)

        get '/system_stats.json'
        expect(response.status).to eq(200)
        expect(response.content_type).to include('application/json')

        json = JSON.parse(response.body)
        expect(json).to have_key('kpis')
        expect(json).to have_key('trends')
      end
    end
  end

  describe '#wiki_trends' do
    context 'when user is not signed in' do
      it 'redirects or returns 401/302' do
        get '/system_stats/wiki_trends.json'
        expect(response.status).to eq(302).or eq(401)
      end
    end

    context 'when user is not an admin' do
      before do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
      end

      it 'returns 302 or 401' do
        get '/system_stats/wiki_trends.json'
        expect(response.status).to eq(302).or eq(401)
      end
    end

    context 'when user is an admin' do
      before do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(admin)
      end

      it 'returns JSON with expected structure' do
        create(:system_stat, snapshot_date: Time.zone.today)

        get '/system_stats/wiki_trends.json'
        expect(response.status).to eq(200)
        expect(response.content_type).to include('application/json')

        json = JSON.parse(response.body)
        expect(json).to have_key('months')
        expect(json).to have_key('wiki_trends')
        expect(json).to have_key('wiki_stats')
      end
    end
  end

  describe '#facilitators' do
    context 'when user is not signed in' do
      it 'redirects or returns 401/302' do
        get '/system_stats/facilitators.json'
        expect(response.status).to eq(302).or eq(401)
      end
    end

    context 'when user is not an admin' do
      before do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
      end

      it 'returns 302 or 401' do
        get '/system_stats/facilitators.json'
        expect(response.status).to eq(302).or eq(401)
      end
    end

    context 'when user is an admin' do
      before do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(admin)
      end

      it 'returns JSON with expected structure' do
        f_user = create(:user, username: 'test_facilitator')
        create(:facilitator_stat, user: f_user, total_edits: 1000)

        get '/system_stats/facilitators.json'
        expect(response.status).to eq(200)
        expect(response.content_type).to include('application/json')

        json = JSON.parse(response.body)
        expect(json).to have_key('facilitators')
        expect(json['facilitators'].length).to eq(1)

        first_facilitator = json['facilitators'].first
        expect(first_facilitator['username']).to eq('test_facilitator')
        expect(first_facilitator['edits']).to eq(1000)
        expect(first_facilitator['courses']).to eq(3)
        expect(first_facilitator['activeCourses']).to eq(1)
        expect(first_facilitator['students']).to eq(45)
        expect(first_facilitator['newEditors']).to eq(25)
        expect(first_facilitator['activeInYear']).to eq('Yes')
      end
    end
  end
end
