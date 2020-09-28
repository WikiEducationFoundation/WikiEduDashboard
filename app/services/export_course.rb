# frozen_string_literal: true

#= Exports a course into a file that can be imported in an LMS
class ExportCourse
  def initialize(course)
    @course = course
    generate_file
  end

  private

  def generate_file
    @canvas_course = CanvasCc::CanvasCC::Models::Course.new
    @canvas_course.identifier = @course.slug
    @canvas_course.title = @course.title
    @canvas_course.rubrics << main_assignment_rubric
    dir = 'public/assets/system/course_exports'
    FileUtils.mkdir_p dir
    output = CanvasCc::CanvasCC::CartridgeCreator.new(@canvas_course).create(dir)
    output
  end

  def main_assignment_rubric
    @main_rubric = CanvasCc::CanvasCC::Models::Rubric.new
    rubric_data = Rubric.new('wikipedia_article_rubric.yml')
    @main_rubric.title = rubric_data.title
    rubric_data.criteria.each do |criterion|
      canvas_criterion = CanvasCc::CanvasCC::Models::RubricCriterion.new
      canvas_criterion.id = criterion['id']
      canvas_criterion.description = criterion['description']
      canvas_criterion.long_description = criterion['long_description']
      canvas_criterion.ratings = ratings(criterion)
      @main_rubric.criteria << canvas_criterion
    end
    @main_rubric
  end

  def ratings(criterion)
    criterion['ratings'].map do |rating|
      CanvasCc::CanvasCC::Models::Rating.new.tap do |canvas_rating|
        canvas_rating.points = rating['points']
        canvas_rating.description = rating['description']
        canvas_rating.long_description = rating['long_description']
      end
    end
  end
end
