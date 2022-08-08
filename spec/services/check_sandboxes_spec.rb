# frozen_string_literal: true

require 'rails_helper'

describe CheckSandboxes do
  let(:course) { create(:course) }
  let(:user) { create(:user) }
  let(:sandbox) do
    # Example with violations: https://en.wikipedia.org/wiki/User:Sage_(Wiki_Ed)/unreliable
    create(:article, title: 'Sage_(Wiki_Ed)/unreliable', namespace: Article::Namespaces::USER)
  end

  before do
    create(:courses_user, course:, user:)
    create(:revision, article: sandbox, user:, date: course.start + 1.day)
  end

  it 'returns a list of unreliable source rule violations' do
    VCR.use_cassette('check_sandboxes') do
      result = described_class.new(course:).check_sandboxes
      expect(result.flatten).to include('dailysabah.com')
    end
  end
end
