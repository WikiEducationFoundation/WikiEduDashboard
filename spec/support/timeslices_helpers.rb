# frozen_string_literal: true

#= Helper for comparing course timeslices with a fixture file.
module TimeslicesHelpers
  def compare_course_wiki_timeslices(course, path)
    cw_actual = course.course_wiki_timeslices.map do |ts|
      ts.attributes.slice(
        'start', 'end',
        'character_sum', 'references_count',
        'revision_count', 'stats',
        'last_mw_rev_datetime', 'needs_update'
      )
    end

    cw_expected = YAML.load_file(Rails.root + path + 'expected_timeslices.yml')

    cw_expected.each_value do |ts|
      # Ensure dates are timezone and not strings
      ts['start'] = ts['start'].to_time.in_time_zone('UTC')
      ts['end'] = ts['end'].to_time.in_time_zone('UTC')
      if ts['last_mw_rev_datetime']
        ts['last_mw_rev_datetime'] =
          ts['last_mw_rev_datetime'].to_time.in_time_zone('UTC')
      end
    end

    expect(cw_actual).to match_array(cw_expected.values)
  end

  def compare_article_course_timeslices(course, path)
    ac_actual = course.article_course_timeslices.map do |ts|
      ts.attributes.slice(
        'start', 'end', 'character_sum', 'references_count',
        'revision_count', 'new_article', 'tracked', 'first_revision', 'user_ids'
      )
    end

    ac_expected = YAML.load_file(Rails.root + path + 'expected_ac_timeslices.yml')

    ac_expected.each_value do |ts|
      # Ensure dates are timezone and not strings
      ts['start'] = ts['start'].to_time.in_time_zone('UTC')
      ts['end'] = ts['end'].to_time.in_time_zone('UTC')
      ts['first_revision'] = ts['first_revision'].to_time.in_time_zone('UTC')
      ts['user_ids'] = [user.id]
    end

    expect(ac_actual).to match_array(ac_expected.values)
  end

  def compare_course_user_wiki_timeslices(course, path)
    cuw_actual = course.course_user_wiki_timeslices.map do |ts|
      ts.attributes.slice(
        'start', 'end', 'character_sum_ms', 'character_sum_us',
        'character_sum_draft', 'references_count', 'revision_count'
      )
    end

    cuw_expected = YAML.load_file(Rails.root + path + 'expected_cuw_timeslices.yml')

    cuw_expected.each_value do |ts|
      # Ensure dates are timezone and not strings
      ts['start'] = ts['start'].to_time.in_time_zone('UTC')
      ts['end'] = ts['end'].to_time.in_time_zone('UTC')
    end

    expect(cuw_actual).to match_array(cuw_expected.values)
  end
end
