# frozen_string_literal: true

FactoryBot.define do
  factory :email, class: 'OpenStruct' do
    # Assumes Griddler.configure.to is :hash (default)
    to do
      [
        {
          full: 'to_user@email.com',
          email: 'to_user@email.com',
          token: 'to_user',
          host: 'email.com',
          name: nil
        }
      ]
    end
    from do
      {
        token: 'from_user',
        host: 'email.com',
        email: 'from_email@email.com',
        full: 'From User <from_user@email.com>', name: 'From User'
      }
    end

    subject { 'email subject' }

    body { 'Hello!' }
    raw_body { 'Hello!' }
    attachments { '0' }

    trait :with_attachment do
      attachments do
        [
          ActionDispatch::Http::UploadedFile.new(
            filename: 'img.png',
            type: 'image/png',
            tempfile: File.new("#{__dir__}/fixtures/img.png")
          )
        ]
      end
    end
  end
end
