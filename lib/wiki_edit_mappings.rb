# frozen_string_literal: true

# Class returns template mappings for WikiEdu and P&E Dashboards, respectively
class WikiEditMappings
  TEMPLATES = {
    "dashboard.wikiedu.org" => {
      "editor" => "student editor",
      "instructor" => "course instructor",
      "course_assignment" => "course assignment",
      "table" => "students table",
      "table_row" => "students table row",
      "course" => "course details",
      "timeline" => "start of course timeline"
    },
    "outreachdashboard.wmflabs.org" => {
      "editor" => "participant editor",
      "instructor" => "program instructor",
      "course_assignment" => "program assignment",
      "table" => "participants table",
      "table_row" => "participants table row",
      "course" => "program details",
      "timeline" => "start of program timeline"
    }
  }

  def self.get_template(template_key)
    dashboard_url = ENV['dashboard_url']
    TEMPLATES[dashboard_url][template_key]
  end
end
