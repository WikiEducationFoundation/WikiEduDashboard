# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/email_processor"

describe EmailProcessor do
  let(:forwarded_email) do
    <<~FORWARDED
      -------- Forwarded Message --------
      Subject: question about editing
      Date:	Thu, 25 Apr 2019 16:20:51 -0700
      From:	Jess Profess <jprof@edu.edu>
      To:	helaine@wikiedu.org

      Hi Helaine. What went wrong with these pages? 🙂

      Breastfeeding - fine
      https://en.wikipedia.org/wiki/Breastfeeding

      Michał Wołodyjowski - draft
      https://en.wikipedia.org/wiki/Draft:Micha%C5%82_Wo%C5%82odyjowski


      Jess

      --
      Jess Profess
      Professor
      Education University, Department of Studies
      jprof@edu.edu
      Pronouns: she/they
    FORWARDED
  end

  describe '#process' do
    let(:course) { create(:course) }

    let(:student) { create(:user, username: 'student', email: 'student@email.com') }
    let!(:student_courses_user) { create(:courses_user, user: student, course:) }

    let(:expert) { create(:admin, greeter: true, username: 'expert', email: 'expert@wikiedu.org') }
    let!(:expert_courses_user) do
      create(:courses_user, user: expert, course:, role: 4)
    end

    it 'will ignore emails with the specified code' do
      body = <<~EXAMPLE
        This is an automated email\r\n\r\nignore_creating_dashboard_ticket
      EXAMPLE
      email = create(:email,
                     to: [{ email: expert.email }],
      from: { email: student.email },
      body:)
      processor = described_class.new(email)
      processor.process

      expect(TicketDispenser::Ticket.all.count).to eq(0)
      expect(TicketDispenser::Message.all.count).to eq(0)
    end

    it 'creates an associated Ticket and Message' do
      expect(TicketDispenser::Ticket.all.count).to eq(0)
      expect(TicketDispenser::Message.all.count).to eq(0)

      email = create(:email,
                     to: [{ email: expert.email }],
      from: { email: student.email })
      processor = described_class.new(email)
      processor.process

      expect(TicketDispenser::Ticket.all.count).to eq(1)
      expect(TicketDispenser::Message.all.count).to eq(1)

      ticket = TicketDispenser::Ticket.first
      expect(ticket.owner).to eq(expert)
      expect(ticket.project).to eq(course)

      message = ticket.messages.first
      expect(message.sender).to eq(student)
    end

    it 'does not set the sender if it cannot be found' do
      email = create(:email,
                     to: [{ email: expert.email }],
      from: { full: 'other@email.com', email: 'other@email.com' })
      processor = described_class.new(email)
      processor.process

      expect(TicketDispenser::Ticket.all.count).to eq(1)
      expect(TicketDispenser::Message.all.count).to eq(1)

      ticket = TicketDispenser::Ticket.first
      expect(ticket.owner).to eq(expert)

      message = ticket.messages.first
      expect(message.sender).to eq(nil)
    end

    it 'does not set an owner if it is not addressed to a Wikipedia Expert' do
      email = create(:email,
                     to: [{ email: 'unknown@wikiedu.org' }],
                     from: { email: student.email })
      processor = described_class.new(email)
      processor.process

      expect(TicketDispenser::Ticket.all.count).to eq(1)
      expect(TicketDispenser::Message.all.count).to eq(1)

      ticket = TicketDispenser::Ticket.first
      expect(ticket.owner).to eq(nil)
    end

    it 'sets the course based off of an email link if there is none' do
      student_courses_user.destroy
      slug = course.slug
      body = "Example email test\r\n\r\nhttps://example.org/courses/#{slug}"

      email = create(:email,
                     to: [{ email: expert.email }],
                     from: { email: student.email },
                     body:,
                     raw_body: body)
      processor = described_class.new(email)
      processor.process

      expect(TicketDispenser::Ticket.all.count).to eq(1)
      expect(TicketDispenser::Message.all.count).to eq(1)

      ticket = TicketDispenser::Ticket.first
      expect(ticket.project).to eq(course)
    end

    it 'can thread a message with the right ticket' do
      ticket = TicketDispenser::Dispenser.call(
        content: 'Message content',
        owner_id: expert.id,
        sender_id: student.id
      )
      email_body = "Hi there,
      Thanks for responding! ...

      -- DO NOT DELETE ANYTHING BELOW THIS LINE --
      **ref_#{ticket.reference_id}_ref**
      -- REPLY ABOVE THIS LINE --
      "
      email = create(:email, to: [{ email: expert.email }],
                             from: { email: student.email },
                             body: email_body,
                             raw_body: email_body)
      processor = described_class.new(email)
      processor.process

      expect(ticket.messages.length).to eq(2)
    end

    it 'creates a new thread if the original thread is not found' do
      ticket = TicketDispenser::Dispenser.call(
        content: 'Message content',
        owner_id: expert.id,
        sender_id: student.id
      )
      email_body = "Hi there,
      Thanks for responding! ...

      -- DO NOT DELETE ANYTHING BELOW THIS LINE --
      **ref_#{ticket.reference_id}_ref**
      -- REPLY ABOVE THIS LINE --
      "
      email = create(:email, to: [{ email: expert.email }],
                             from: { email: student.email },
                             body: email_body,
                             raw_body: email_body)
      ticket.destroy
      expect(TicketDispenser::Ticket.count).to eq(0)
      processor = described_class.new(email)
      processor.process

      expect(TicketDispenser::Ticket.count).to eq(1)
      expect(TicketDispenser::Ticket.last.messages.last.content).to include('Hi there,')
    end

    context 'forwarded emails when the sender uses an email that is not in the Users table' do
      let!(:sender) { create(:user, username: 'Jprof', email: 'jprof-alternative@edu.edu') }

      it 'assigns the owner and the sender_email appropriately' do
        email = create(:email,
                       to: [{ email: expert.email }],
                       from: { email: 'helaine@wikiedu.org' },
                       raw_body: forwarded_email)
        processor = described_class.new(email)
        processor.process

        expect(TicketDispenser::Ticket.all.count).to eq(1)
        expect(TicketDispenser::Message.all.count).to eq(1)

        ticket = TicketDispenser::Ticket.first
        message = TicketDispenser::Message.first
        expect(ticket.owner).to eq(expert)
        expect(message.details[:sender_email]).to eq('jprof@edu.edu')
        expect(message.content).to include('What went wrong with these pages?')
      end
    end

    context 'forwarded emails from a known email address' do
      let!(:sender) { create(:user, username: 'Jprof', email: 'jprof@edu.edu') }

      it 'assigns the owner and the sender_email appropriately' do
        email = create(:email,
                       to: [{ email: expert.email }],
                       from: { email: 'helaine@wikiedu.org' },
                       raw_body: forwarded_email)
        processor = described_class.new(email)
        processor.process

        expect(TicketDispenser::Ticket.all.count).to eq(1)
        expect(TicketDispenser::Message.all.count).to eq(1)

        ticket = TicketDispenser::Ticket.first
        message = TicketDispenser::Message.first
        expect(ticket.owner).to eq(expert)
        expect(message.sender).to eq(sender)
      end
    end

    it 'does not assign forwarded emails to a sender if one cannot be found' do
      student
      create(:user, username: 'noemail', email: nil)
      body = <<~EXAMPLE
        Example email test\r\n\r\n
      EXAMPLE
      domain = ENV['TICKET_FORWARDING_DOMAIN']
      email = create(:email,
                     to: [{ email: expert.email }],
                     from: { email: "dashboard@#{domain}" },
                     raw_body: body)
      processor = described_class.new(email)
      processor.process

      expect(TicketDispenser::Ticket.all.count).to eq(1)
      expect(TicketDispenser::Message.all.count).to eq(1)

      ticket = TicketDispenser::Ticket.first
      message = TicketDispenser::Message.first
      expect(ticket.owner).to eq(expert)
      expect(message.sender).to eq(nil)
    end

    it 'includes the subject, sender email, and carbon copied emails by default' do
      email = create(:email,
                     to: [{ email: expert.email }],
                     cc: [{ email: 'carbon-coby@email.com' }],
                     from: { email: student.email },
                     subject: 'Subject')
      processor = described_class.new(email)
      processor.process

      message = TicketDispenser::Message.first
      expect(message.details[:subject]).to eq('Subject')
      expect(message.details[:sender_email]).to eq(student.email)
      expect(message.details[:cc]).to eq([{ email: 'carbon-coby@email.com' }])
    end
  end

  describe '#retrieve_forwarder_email' do
    it 'returns the first email from a forwarded message' do
      body = <<~EXAMPLE
        Example email test\r\n\r\n---------- Forwarded message ---------\r\nFrom:
        Person A <aaa@email.com>\r\nDate: Mon, Apr 8, 2019 at 3:42 PM\r\n
        Subject: Help!\r\nTo: <bbb@email.com>\r\n\r\n\r\nHelp message\r\n
      EXAMPLE
      email = build(:email, raw_body: body)
      expected_result = 'aaa@email.com'

      expect(described_class.new(email).retrieve_original_sender_email).to eq(expected_result)
    end
  end

  describe '#retrieve_course_by_url' do
    it 'returns a course slug from a URL' do
      body = <<~EXAMPLE
        Example email test\r\n\r\nhttps://example.org/courses/example/slug
      EXAMPLE
      email = build(:email, raw_body: body)
      expected_result = 'example/slug'

      expect(described_class.new(email).retrieve_course_slug_by_url).to eq(expected_result)
    end

    it 'returns a course slug from a complex URL' do
      body = <<~EXAMPLE
        Example email test\r\n\r\nhttps://example.org/courses/example/slug/articles/edited?showArticle=1
      EXAMPLE
      email = build(:email, raw_body: body)
      expected_result = 'example/slug'

      expect(described_class.new(email).retrieve_course_slug_by_url).to eq(expected_result)
    end

    it 'returns nil if a matching slug cannot be found' do
      body = <<~EXAMPLE
        Example email test\r\n\r\nhttps://example.org/courses/incorrect
      EXAMPLE
      email = build(:email, raw_body: body)

      expect(described_class.new(email).retrieve_course_slug_by_url).to eq(nil)
    end
  end
end
