# frozen_string_literal: true

class Rubric
  def initialize(rubric_file)
    @rubric = YAML.load_file("app/content/rubrics/#{rubric_file}")
  end

  def criteria
    @rubric['criteria']
  end

  def title
    @rubric['title']
  end
end
