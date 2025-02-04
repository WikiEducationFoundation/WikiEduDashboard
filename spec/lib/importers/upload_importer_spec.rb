# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/importers/upload_importer"

describe UploadImporter do
  describe '.import_all_uploads' do
    it 'finds and saves files uploaded to Commons' do
      create(:user, username: 'Guettarda')
      VCR.use_cassette 'cached/commons/import_all_uploads' do
        described_class.import_all_uploads(User.all)
        expect(CommonsUpload.all.count).to be > 50
      end
    end

    # This one takes forever, so we won't include it in the test suite.
    # It replicates https://github.com/WikiEducationFoundation/WikiEduDashboard/issues/1314

    # it 'works for users with many uploads' do
    #   create(:user, username: 'Pharos') # User has nearly 200_000 uploads
    #   VCR.use_cassette 'commons/import_all_uploads' do
    #     UploadImporter.import_all_uploads(User.all)
    #     expect(CommonsUpload.all.count).to be > 50
    #   end
    # end
  end

  describe '.update_usage_count_by_course' do
    before do
      user = create(:user,
                    username: 'Guettarda')
      course = create(:course, start: '2006-01-01', end: 1.day.from_now)
      create(:courses_user, course_id: course.id, user_id: user.id,
                            role: CoursesUsers::Roles::STUDENT_ROLE)
    end

    it 'counts and saves how many times files are used' do
      VCR.use_cassette 'cached/commons/import_all_uploads' do
        described_class.import_uploads_for_current_users
      end
      VCR.use_cassette 'cached/commons/update_usage_count' do
        described_class.update_usage_count_by_course(Course.current)
        peas_photo = CommonsUpload.find(543972)
        expect(peas_photo.usage_count).to be > 1
      end
    end
  end

  describe '.find_deleted_files' do
    before do
      create(:commons_upload, id: 4)
      create(:commons_upload, id: 20523186)
      VCR.use_cassette 'cached/commons/find_deleted_files' do
        described_class.find_deleted_files
      end
    end

    it 'marks missing files as deleted' do
      missing_file = CommonsUpload.find(4)
      expect(missing_file.deleted).to eq(true)
    end

    it 'does not affect non-deleted files' do
      existing_file = CommonsUpload.find(20523186)
      expect(existing_file.deleted).to eq(false)
    end
  end

  describe '.import_all_missing_urls' do
    it 'processes all files that need thumbnails' do
      create(:commons_upload, id: 174, file_name: 'File:Magnolia × soulangeana blossom.jpg')
      expect(CommonsUpload.last.thumburl).to be_nil
      VCR.use_cassette 'cached/commons/import_all_missing_urls' do
        described_class.import_all_missing_urls
      end
      expect(CommonsUpload.last.thumburl).not_to be_nil
    end
  end

  describe '.import_urls_in_batches' do
    it 'finds and saves Commons thumbnail urls' do
      create(:user,
             username: 'Guettarda')
      VCR.use_cassette 'cached/commons/import_all_uploads' do
        described_class.import_all_uploads(User.all)
      end
      VCR.use_cassette 'cached/commons/import_urls_in_batches' do
        described_class.import_urls_in_batches([CommonsUpload.find(543972)])
        peas_photo = CommonsUpload.find(543972)
        expect(peas_photo.thumburl[0...24]).to eq('https://upload.wikimedia')
      end
    end
  end

  describe '.import_upload' do
    let(:user) { create(:user) }

    it 'saves files with four-byte unicode characters' do
      # Example from https://commons.wikimedia.org/wiki/File:東-bronze-shang.svg
      file_data = {
        'user' => user.username,
        'title' => 'File:東-bronze-shang.svg',
        'pageid' => 12345
      }
      described_class.import_upload(file_data)
      expect(CommonsUpload.last.id).to eq(12345)
      # Whether this gets saved with CGI.escape depends on whether the database can handle
      # 4-byte characters. In new databases on travis-ci, it can, but in production might not.
      expect(CGI.unescape(CommonsUpload.last.file_name)).to eq('File:東-bronze-shang.svg')
    end

    it 'saves a file with 4-byte characters in the title' do
      # This isn't the file's name anymore, and I can't find any live examples of such files,
      # but it may come up again, so we still have code for handling this situation.
      file_data = { 'user' => user.username, 'title' => 'File:𣒚-bronze.svg', 'pageid' => 12345 }

      call_count = 0
      allow_any_instance_of(CommonsUpload).to receive(:save) do |upload|
        if call_count.zero?
          call_count += 1
          raise ActiveRecord::StatementInvalid
        end
        upload.save!
      end

      described_class.import_upload(file_data)
      expect(CommonsUpload.last.id).to eq(12345)
    end
  end
end
