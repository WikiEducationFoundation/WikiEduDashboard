# frozen_string_literal: true

require 'rails_helper'

describe LtiConsumerKey do
  let(:course) { create(:course) }
  let(:instructor) { create(:user) }

  describe 'issuing' do
    it 'generates a key and a secret' do
      key = described_class.generate_for(course:, user: instructor)
      expect(key.key).to be_present
      expect(key.secret).to be_present
      expect(key.key).not_to eq(key.secret)
    end

    # The secret is a bearer credential an instructor pastes into Canvas, so it
    # must not be readable from the database alone.
    it 'stores the secret encrypted' do
      key = described_class.generate_for(course:, user: instructor)
      sql = "SELECT secret FROM lti_consumer_keys WHERE id = #{key.id}"
      stored = described_class.connection.select_value(sql)
      expect(stored).not_to include(key.secret)
      expect(described_class.find(key.id).secret).to eq(key.secret)
    end

    # Regenerating replaces rather than adds: an install has one working
    # secret, and leaving the previous one usable would defeat the point.
    it 'deactivates the course\'s previous key' do
      first = described_class.generate_for(course:, user: instructor)
      second = described_class.generate_for(course:, user: instructor)
      expect(first.reload).not_to be_active
      expect(second.reload).to be_active
      expect(described_class.active.where(course:).count).to eq(1)
    end

    it 'leaves another course\'s key alone' do
      other = described_class.generate_for(course: create(:course, slug: 'School/Other_(2026)'),
                                           user: instructor)
      described_class.generate_for(course:, user: instructor)
      expect(other.reload).to be_active
    end

    # Two simultaneous regenerations must not leave two active keys. A real
    # race cannot run inside a transactional example, so this pins the
    # mechanism instead: the course row is locked for the transaction, which
    # makes the second request wait behind the first and then replace its key.
    it 'locks the course row while replacing the key' do
      statements = []
      callback = ->(event) { statements << event.payload[:sql] }
      ActiveSupport::Notifications.subscribed(callback, 'sql.active_record') do
        described_class.generate_for(course:, user: instructor)
      end
      expect(statements).to include(a_string_matching(/FROM `courses`.*FOR UPDATE/m))
    end
  end

  # A key that outlived its course would still verify a launch, whose course
  # claim then names a row that no longer exists; the foreign key takes the key
  # down with the course instead.
  describe 'when the course is deleted' do
    it 'goes with it' do
      key = described_class.generate_for(course:, user: instructor)
      course.destroy
      expect(described_class.exists?(key.id)).to be false
    end
  end

  describe 'the first launch' do
    let(:key) { described_class.generate_for(course:, user: instructor) }

    it 'is not activated until a launch arrives' do
      expect(key).not_to be_activated
      expect(key.lms_instance_guid).to be_nil
    end

    it 'pins the Canvas instance and stamps the activation' do
      key.record_launch!('guid-from-canvas')
      expect(key.reload).to be_activated
      expect(key.lms_instance_guid).to eq('guid-from-canvas')
      expect(key.last_launch_at).to be_present
    end

    it 'only stamps the launch time on later launches' do
      key.record_launch!('guid-from-canvas')
      activated = key.reload.activated_at
      travel_to(1.hour.from_now) { key.record_launch!('guid-from-canvas') }
      expect(key.reload.activated_at).to be_within(1.second).of(activated)
      expect(key.last_launch_at).to be > activated
    end
  end

  describe '#usable_for?' do
    let(:key) { described_class.generate_for(course:, user: instructor) }

    it 'accepts the first launch from any Canvas, which is what pins it' do
      expect(key).to be_usable_for('any-guid')
    end

    # The pin only protects if it is always set: a first launch with no guid
    # would otherwise activate the key unpinned, usable from anywhere for good.
    it 'refuses a launch that names no Canvas instance' do
      expect(key).not_to be_usable_for(nil)
      expect(key).not_to be_usable_for('')
    end

    # The property LTIAAS's one global key cannot have: a leaked secret is
    # useless from a Canvas other than the one it was first used from.
    it 'accepts only the pinned Canvas afterwards' do
      key.record_launch!('the-real-canvas')
      expect(key).to be_usable_for('the-real-canvas')
      expect(key).not_to be_usable_for('someone-elses-canvas')
    end

    it 'refuses a deactivated key' do
      key.update!(active: false)
      expect(key).not_to be_usable_for('any-guid')
    end

    it 'refuses a key that was issued and never used' do
      key
      travel_to((described_class::UNACTIVATED_LIFETIME + 1.day).from_now) do
        expect(key.reload).to be_expired
        expect(key.reload).not_to be_usable_for('any-guid')
      end
    end

    # Expiry covers the window before a key proves itself. Once it has, the
    # install keeps working for as long as the course runs.
    it 'does not expire a key that has been used' do
      key.record_launch!('the-real-canvas')
      travel_to((described_class::UNACTIVATED_LIFETIME + 30.days).from_now) do
        expect(key.reload).not_to be_expired
        expect(key.reload).to be_usable_for('the-real-canvas')
      end
    end
  end
end
