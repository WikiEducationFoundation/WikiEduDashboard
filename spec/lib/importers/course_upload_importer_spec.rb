# frozen_string_literal: true

require 'rails_helper'
require Rails.root.join('lib/importers/course_upload_importer')

describe CourseUploadImporter do
  let(:course) do
    create(:course, start: '2018-03-07'.to_date, end: '2018-03-11'.to_date)
  end
  let(:user) { create(:user, username: 'Kippelboy') }

  before do
    create(:courses_user, user:, course:)
  end

  describe '.run' do
    it 'imports uploads with thumburls and usage counts for the course' do
      VCR.use_cassette 'course_upload_importer/kippleboy' do
        described_class.new(course).run
        expect(course.reload.uploads.count).to eq(5)
        # https://commons.wikimedia.org/wiki/File%3AVaga_feminista_8M_2018_a_Sabadell_02.jpg
        upload = course.uploads.third
        expect(upload.thumburl).not_to be_nil
        expect(upload.usage_count).not_to be_nil
      end
    end
  end
end
