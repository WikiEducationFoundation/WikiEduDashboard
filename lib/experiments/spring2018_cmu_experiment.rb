# frozen_string_literal: true

class Spring2018CmuExperiment
  def self.process_courses
    return unless Features.wiki_ed?
    unless Setting.exists?(key: 'spring_2018_cmu_experiment')
      Setting.create(key: 'spring_2018_cmu_experiment', value: { enrolled_courses_count: 0 })
    end

    Campaign.find_by(slug: 'spring_2018').courses.each do |course|
      new(course).process_course
    end
  end

  def self.course_list
    csv_data = [%w[course status email_sent_at]] # headers
    Campaign.find_by(slug: 'spring_2018').courses.each do |course|
      flags = course.flags
      csv_data << [course.slug, flags[STATUS_KEY], flags[EMAIL_SENT_AT]]
    end

    CSV.generate { |csv| csv_data.each { |line| csv << line } }
  end

  STATUS_KEY = :spring_2018_cmu_experiment
  EMAIL_SENT_AT = :spring_2018_cmu_experiment_email_sent_at
  EMAIL_CODE = :spring_2018_cmu_experiment_email_code
  REMINDER_SENT_AT = :spring_2018_cmu_experiment_reminder_sent_at
  def initialize(course)
    @course = course
    @status = course.flags[STATUS_KEY]
    @experiment_setting = Setting.find_by(key: 'spring_2018_cmu_experiment')
  end

  def process_course
    enroll_in_experiment if @status.nil?
    send_email_invitation if @status == 'ready_for_email'
    send_email_reminder if @status == 'email_sent' && invited_over_a_week_ago?
  end

  def opt_in
    update_status 'opted_in'
    add_trainings_to_default_blocks
  end

  def opt_out
    update_status 'opted_out'
  end

  private

  CONTROL_FACTOR = 3 # 1 in 3 courses will be in the control group
  def enroll_in_experiment
    enrollment_number = @experiment_setting.value[:enrolled_courses_count] + 1

    if (enrollment_number % CONTROL_FACTOR).zero?
      update_status 'control'
    else
      update_status 'ready_for_email'
    end

    @experiment_setting.value[:enrolled_courses_count] = enrollment_number
    @experiment_setting.save!
  end

  def update_status(new_status, email_just_sent: false, email_code: nil, reminder_just_sent: false)
    @course.flags[STATUS_KEY] = new_status
    @course.flags[EMAIL_SENT_AT] = Time.zone.now.to_s if email_just_sent
    @course.flags[EMAIL_CODE] = email_code if email_code.present?
    @course.flags[REMINDER_SENT_AT] = Time.zone.now.to_s if reminder_just_sent
    @course.save
    @status = new_status
  end

  def send_email_invitation
    email_code = GeneratePasscode.call(length: 16)
    first_instructor = @course.instructors.first
    Spring2018CmuExperimentMailer.send_invitation(@course, first_instructor, email_code)
    update_status('email_sent', email_just_sent: true, email_code: email_code)
    sleep 2 unless Rails.env.test? # pause to avoid email rate-limiting
  end

  def invited_over_a_week_ago?
    invited_at = Time.zone.parse(@course.flags[EMAIL_SENT_AT])
    invited_at < 1.week.ago
  end

  def send_email_reminder
    email_code = @course.flags[EMAIL_CODE]
    first_instructor = @course.instructors.first
    Spring2018CmuExperimentMailer.send_invitation(@course, first_instructor, email_code,
                                                  reminder: true)
    update_status('reminder_sent', reminder_just_sent: true)
    sleep 2 unless Rails.env.test? # pause to avoid email rate-limiting
  end

  TRAINING_MAP = {
    18 => /Get started on Wikipedia/, # get started
    19 => /Add to an article/, # evaluate and improve an article
    20 => /Peer review and copy edit/ # peer review
  }.freeze
  def add_trainings_to_default_blocks
    TRAINING_MAP.each do |training_module_id, block_matcher|
      block = @course.blocks.detect { |b| b.title =~ block_matcher }
      next if block.nil?
      block.training_module_ids |= [training_module_id]
      block.save
    end
  end
end
