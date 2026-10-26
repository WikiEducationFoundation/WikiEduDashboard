# frozen_string_literal: true

# The tags a wizard can produce, as [panel key, tag] pairs: each option's tag
# under its panel's key, plus the assignment type tags under 'index', the key
# of the assignment type panel the frontend adds. Wizard submissions come from
# the client, so WizardTimelineManager writes only tags found here.
class WizardTagOptions
  WIZARD_DIR = "#{Rails.root}/config/wizard"
  ASSIGNMENT_TYPE_FILES = %w[wizard_index.yml extra_timeline_options.yml].freeze

  def initialize(wizard_id)
    @wizard_id = wizard_id
  end

  def permitted?(key, tag)
    permitted.include?([key, tag])
  end

  private

  def permitted
    @permitted ||= (panel_tags + assignment_type_tags).to_set
  end

  def panel_tags
    load_yaml("#{@wizard_id}/wizard.yml").flat_map do |panel|
      Array(panel['options']).filter_map { |option| [panel['key'], option['tag']] if option['tag'] }
    end
  end

  def assignment_type_tags
    ASSIGNMENT_TYPE_FILES.flat_map do |file|
      load_yaml(file).filter_map { |option| ['index', option['tag']] if option['tag'] }
    end
  end

  def load_yaml(path)
    YAML.safe_load_file("#{WIZARD_DIR}/#{path}", permitted_classes: []) || []
  end
end
