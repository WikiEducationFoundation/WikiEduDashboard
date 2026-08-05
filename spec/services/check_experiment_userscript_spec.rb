# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/experiments/opt_in_experiment"

describe CheckExperimentUserscript do
  let(:experiment) { Fall2026ResearchExperiment.new }
  let(:course) { create(:course, start: Date.new(2026, 9, 1)) }
  let(:student) { create(:user, username: 'Student') }
  let(:courses_user) do
    create(:courses_user, course:, user: student, role: CoursesUsers::Roles::STUDENT_ROLE)
  end
  let(:record) do
    ExperimentCoursesUser.create!(experiment_slug: experiment.slug, courses_user:,
                                  status: :opted_in)
  end

  def stub_common_js(content)
    allow_any_instance_of(WikiApi).to receive(:get_page_content).and_return(content)
  end

  it 'is not installed when common.js does not exist' do
    stub_common_js ''
    expect(described_class.new(record, experiment).status).to eq(:not_installed)
  end

  it 'is not installed when common.js has only unrelated content' do
    stub_common_js "importScript('User:Someone/other.js');\n"
    expect(described_class.new(record, experiment).status).to eq(:not_installed)
  end

  it 'records the install when the import line is present' do
    stub_common_js "#{experiment.userscript_import_line}\n"
    expect(described_class.new(record, experiment).status).to eq(:installed)
    expect(record.reload.userscript_installed_at).to be_present
  end

  it 'still counts the script as installed when the student retyped the quoting' do
    # Double quotes, where the canonical import line uses single quotes.
    stub_common_js %(importScript("#{Fall2026ResearchExperiment::USERSCRIPT_PAGE}"); // mine\n)
    expect(described_class.new(record, experiment).status).to eq(:installed)
  end

  it 'leaves an existing install timestamp untouched' do
    record.update!(userscript_installed_at: 3.days.ago)
    stub_common_js "#{experiment.userscript_import_line}\n"
    expect { described_class.new(record, experiment) }
      .not_to(change { record.reload.userscript_installed_at })
  end

  it 'reports :not_installed without raising when the wiki cannot be read' do
    allow_any_instance_of(WikiApi).to receive(:get_page_content)
      .and_raise(WikiApi::PageFetchError.new('User:Student/common.js', 503))
    allow(Sentry).to receive(:capture_exception)
    expect(described_class.new(record, experiment).status).to eq(:not_installed)
  end
end
