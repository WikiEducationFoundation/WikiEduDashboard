# frozen_string_literal: true

class Fall2017CmuExperiment
  def self.process_courses
    Campaign.find_by(slug: 'fall_2017').courses.each do |course|
      new(course).process_course
    end
  end

  STATUS_KEY = :fall_2017_cmu_experiment
  EMAIL_SENT_AT = :fall_2017_cmu_experiment_email_sent_at
  EMAIL_CODE = :fall_2017_cmu_experiment_email_code
  def initialize(course)
    @course = course
    @status = course.flags[STATUS_KEY]
  end

  def process_course
    enroll_in_experiment if @status.nil?
    send_email_invitation if @status == 'ready_for_email'
    update_status_from_tags
  end

  def opt_in
    update_status 'opted_in'
  end

  def opt_out
    update_status 'opted_out'
  end

  private

  CONTROL_RATIO = 0.33333
  def enroll_in_experiment
    if rand > CONTROL_RATIO
      update_status 'ready_for_email'
    else
      update_status 'control'
    end
  end

  def update_status(new_status, email_just_sent: false, email_code: nil)
    @course.flags[STATUS_KEY] = new_status
    @course.flags[EMAIL_SENT_AT] = Time.now.to_s if email_just_sent
    @course.flags[EMAIL_CODE] = email_code if email_code.present?
    @course.save
    @status = new_status
  end

  def update_status_from_tags
    if course_tags.include? 'fall_2017_cmu_experiment_opted_in'
      update_status 'opted_in'
    elsif course_tags.include? 'fall_2017_cmu_experiment_opted_out'
      update_status 'opted_out'
    end
  end

  def send_email_invitation
    email_code = Course.generate_passcode + Course.generate_passcode
    first_instructor = @course.instructors.first
    Fall2017CmuExperimentMailer.send_invitation(@course, first_instructor, email_code)
    update_status('email_sent', email_just_sent: true, email_code: email_code)
  end

  def course_tags
    @course_tags ||= @course.tags.pluck(:tag)
  end
end
