# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/analytics/retained_new_editors_stats"


describe RetainedNewEditorsStats do
  let(:course) { create(:course, start: 2.weeks.ago, end: 1.week.ago) }
  let(:wiki) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }
  let(:manager) { described_class.new(course) }

  # Helper to build the nested data structure the class expects: response.data['usercontribs']
  def mock_response_with_contribs(contribs_array)
    instance_double(MediawikiApi::Response, data: { 'usercontribs' => contribs_array })
  end

  before do
    course.update!(home_wiki: wiki)
    
    # Create the fake editors
    %w[Ragesock wikiedStaff].each do |name|
      user = create(:user, username: name, registered_at: course.start + 3.days)
      create(:courses_user, course: course, user: user, role: CoursesUsers::Roles::STUDENT_ROLE)
    end
  end

  context 'when there are no new editors' do
    before { course.courses_users.where(role: CoursesUsers::Roles::STUDENT_ROLE).destroy_all }

    it 'returns 0 immediately' do
      expect(manager.count).to eq(0)
    end
  end

  context 'when two new editors have at least one post-threshold edit' do
    before do
      # IMPORTANT: The first argument to the block is the instance of WikiApi
      allow_any_instance_of(WikiApi).to receive(:query) do |_instance, params|
        usernames = params[:ucuser] || []
        contribs = []
        # Constructing the mock usetcontrib response from the WikiApi
        if usernames.include?('Ragesock')
          contribs << { 'user' => 'Ragesock', 'userid' => 1001 }
        end
        if usernames.include?('wikiedStaff')
          contribs << { 'user' => 'wikiedStaff', 'userid' => 1002 }
        end

        mock_response_with_contribs(contribs)
      end
    end

    it 'counts the distinct users with contributions' do
      expect(manager.count).to eq(2)
    end
  end

  context 'when a user has multiple edits' do
    before do
      allow_any_instance_of(WikiApi).to receive(:query).and_return(
        mock_response_with_contribs([
          { 'user' => 'Ragesock', 'userid' => 1001 },
          { 'user' => 'Ragesock', 'userid' => 1001 }
        ])
      )
    end

    it 'counts them as 1 retained editor' do
      expect(manager.count).to eq(1)
    end
  end

  context 'with many new editors (tests batching)' do
    let(:total_users) { 50 }

    before do
      # Clearing the students from previous before blocks to avoid confusion
      course.courses_users.destroy_all 

      # create 50 new students thta fit the new editor criteria
      total_users.times do |i|
        user = create(:user, username: "User-#{i}", registered_at: course.start + 1.day)
        create(:courses_user, course: course, user: user, role: CoursesUsers::Roles::STUDENT_ROLE)
      end

      # return contribution for EVERY user requested in the batch
      allow_any_instance_of(WikiApi).to receive(:query) do |_instance, params|
        requested_names = params[:ucuser] || []
        
        # Map each requested name to a  contribution hash
        contribs = requested_names.map { |name| { 'user' => name } }
        
        mock_response_with_contribs(contribs)
      end
    end

    it 'processes in batches and sums correctly' do
      expect(manager.count).to eq(50)
    end
  end

end
