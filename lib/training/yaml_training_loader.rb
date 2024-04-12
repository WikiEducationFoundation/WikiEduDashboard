# frozen_string_literal: true

# Loads any of the three types of training content:
# TrainingLibrary, TrainingModule, TrainingSlide
# Source of content is training_content yaml files.
class YamlTrainingLoader
  def initialize(content_class:, **_)
    puts "STEP - Loading #{content_class} from yaml"
    @content_class = content_class # TrainingLibrary, TrainingModule, or TrainingSlide
    @path_to_yaml = content_class.path_to_yaml # a sub-directory of training_content
    @collection = []
  end

  def load_content
    Dir.glob(@path_to_yaml) do |yaml_file|
      @collection << new_from_file(yaml_file)
    end

    return @collection
  end

  private

  def new_from_file(yaml_file)
    slug = File.basename(yaml_file, '.yml')
    slug.gsub!(/^[0-9]+-/, '') if @content_class.trim_id_from_filename
    begin
      content = YAML.load_file(yaml_file)
      validate_id(yaml_file, content)
    rescue StandardError => e
      raise InvalidYamlError, "Looks like there is a problem with #{yaml_file}. #{e}"
    end

    @content_class.inflate(content, slug)
  end

  def validate_id(yaml_file, content)
    return unless @content_class.trim_id_from_filename
    filename_id = File.basename(yaml_file, '.yml')[/^[0-9]+(?=-)/]
    raise InvalidYamlError, "Filename doesn't match id." unless content['id'] == filename_id.to_i
  end

  class InvalidYamlError < StandardError; end
end
