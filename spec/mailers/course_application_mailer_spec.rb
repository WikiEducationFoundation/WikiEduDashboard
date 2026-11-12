# frozen_string_literal: true

require 'rails_helper'

describe CourseApplicationMailer do
  let(:course) { create(:fellows_cohort, title: 'Elections workshop') }
  let(:applicant) do
    create(:user, username: 'Historian', real_name: 'Ada Applicant', email: 'ada@example.edu')
  end
  let(:application) { CourseApplication.create!(course:, user: applicant) }
  let(:manager) { create(:admin, username: 'SSManager', email: 'manager@wikiedu.org') }

  before do
    CourseApplicationForm.create!(course:, acceptance_email: "Welcome!\n\nWe meet Tuesdays." \
                                                             '<script>alert(1)</script>')
    allow(Features).to receive(:email?).and_return(true)
  end

  describe '.send_acceptance' do
    let(:mail) { described_class.send_acceptance(application) }

    it "sends the course's acceptance email, sanitized, to the applicant" do
      expect(mail.to).to eq(['ada@example.edu'])
      expect(mail.subject).to eq('Welcome to your Elections workshop course!')
      body = mail.html_part.body.to_s
      expect(body).to include('Welcome!', 'We meet Tuesdays.')
      expect(body).not_to include('<script>')
    end

    it 'comes from the Scholars & Scientists manager' do
      SpecialUsers.set_user('scholars_and_scientists_manager', manager.username)
      expect(mail.from).to eq(['manager@wikiedu.org'])
      expect(mail.reply_to).to eq(['manager@wikiedu.org'])
    end

    it "comes from the Dashboard's own address while there is no manager" do
      expect(mail.from).to eq(["dashboard@#{ENV['dashboard_url']}"])
    end

    it 'sends nothing to an applicant with no email address' do
      applicant.update!(email: nil)
      expect(mail).to be_nil
    end

    it 'sends nothing while email is off' do
      allow(Features).to receive(:email?).and_return(false)
      expect(mail).to be_nil
    end
  end

  describe '.sender_description' do
    it "names the manager and their email" do
      manager.update!(real_name: 'Sam Manager')
      SpecialUsers.set_user('scholars_and_scientists_manager', manager.username)
      expect(described_class.sender_description).to eq('Sam Manager (manager@wikiedu.org)')
    end

    it "gives the Dashboard's own address while there is no manager" do
      expect(described_class.sender_description).to eq("dashboard@#{ENV['dashboard_url']}")
    end

    it "gives the Dashboard's own address when the manager has no email" do
      manager.update!(email: nil)
      SpecialUsers.set_user('scholars_and_scientists_manager', manager.username)
      expect(described_class.sender_description).to eq("dashboard@#{ENV['dashboard_url']}")
    end
  end

  describe '.send_decline' do
    let(:mail) { described_class.send_decline(application) }

    it 'sends the decline email from the manager to the applicant' do
      SpecialUsers.set_user('scholars_and_scientists_manager', manager.username)
      expect(mail.to).to eq(['ada@example.edu'])
      expect(mail.from).to eq(['manager@wikiedu.org'])
      expect(mail.subject).to eq('Elections workshop update')
    end

    it "greets the applicant and signs off as the manager" do
      manager.update!(real_name: 'Sam Manager')
      SpecialUsers.set_user('scholars_and_scientists_manager', manager.username)
      body = mail.html_part.body.to_s
      expect(body).to include('Hi Ada Applicant,', 'learn.wikiedu.org', 'Sam Manager',
                              'Scholars &amp; Scientists Program Manager', 'manager@wikiedu.org')
    end

    it 'signs off as the organization while there is no manager' do
      body = mail.html_part.body.to_s
      expect(body).to include('WikiEducation')
      expect(body).not_to include('Program Manager')
    end
  end
end
