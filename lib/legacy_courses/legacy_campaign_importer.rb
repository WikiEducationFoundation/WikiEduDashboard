# frozen_string_literal: true
#= Imports and updates campaigns
class LegacyCampaignImporter
  # Take a hash of campaigns and corresponding course_ids, and update the campaigns.
  # raw_ids is the output of WikiLegacyCourses.course_list, and looks like this:
  # { "campaign_slug" => [31, 554, 1234], "campaign_slug_2" => [31, 999, 2345] }
  def self.update_campaigns(raw_ids)
    Course.transaction do
      raw_ids.each do |slug, course_ids|
        campaign = Campaign.find_or_create_by(slug: slug)
        ids_in_campaign = campaign.courses.legacy.map(&:id)

        new_course_ids = course_ids - ids_in_campaign
        new_courses = Course.where(id: new_course_ids)
        add_courses_to_campaign(new_courses, campaign)

        removed_course_ids = ids_in_campaign - course_ids
        removed_courses = Course.where(id: removed_course_ids)
        remove_courses_from_campaign(removed_courses, campaign)
      end
    end
  end

  def self.add_courses_to_campaign(courses, campaign)
    courses.each do |course|
      course.campaigns << campaign
    end
  end

  def self.remove_courses_from_campaign(courses, campaign)
    courses.each do |course|
      course.campaigns.delete(campaign)
    end
  end
end
