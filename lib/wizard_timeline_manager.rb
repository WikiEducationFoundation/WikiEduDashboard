# Routines for building and saving a course timeline after submission of wizard data
class WizardTimelineManager
  ###############
  # Entry point #
  ###############

  def self.update_timeline_and_tags(course, wizard_id, wizard_params)
    new(course, wizard_id, wizard_params).update_timeline_and_tags
  end

  #############
  # Main flow #
  #############

  def initialize(course, wizard_id, wizard_params)
    @course = course
    @output = wizard_params['wizard_output']['output'] || []
    @logic = wizard_params['wizard_output']['logic'] || []
    @tags = wizard_params['wizard_output']['tags'] || []

    # Load the wizard content building blocks.
    content_path = "#{Rails.root}/config/wizard/#{wizard_id}/content.yml"
    @all_content = YAML.load(File.read(File.expand_path(content_path, __FILE__)))
  end

  def update_timeline_and_tags
    # Parse the submitted wizard data and collect selected content.

    content_groups = @output.map do |content_key|
      @all_content[content_key]
    end

    # Build a timeline array
    # Quirk: Will stuff blocks into last week if averages don't line up nicely
    timeline = build_timeline(content_groups)

    # Create and save week/block objects based on the object generated above
    save_timeline(timeline)

    # Save any tags that have been generated from this Wizard output
    add_tags
  end

  ###################
  # Private methods #
  ###################

  private

  def build_timeline(content_groups)
    total_weeks = ((@course.timeline_end - @course.timeline_start) / 7).ceil
    available_weeks = total_weeks - @course.weeks.size

    return [] if available_weeks <= 0

    timeline = content_groups.flatten.map do |week|
      OpenStruct.new(
        weight: week['weight'],
        blocks: week['blocks']
      )
    end

    while timeline.size > available_weeks
      low_weight = 1000       # arbitrarily high number
      low_cons = nil
      timeline.each_cons(2) do |week_set|
        next unless week_set.size == 2
        cons_weight = week_set[0].weight + week_set[1].weight
        if cons_weight < low_weight
          low_weight = cons_weight
          low_cons = week_set
        end
      end
      low_cons[0][:weight] += low_cons[1][:weight]
      low_cons[0][:blocks] += low_cons[1][:blocks]
      timeline.delete low_cons[1]
    end
    timeline
  end

  def save_timeline(timeline)
    new_week = nil
    week_finished = false
    timeline.each do |week|
      week[:blocks].each_with_index do |block, i|
        # Skip blocks with unmet 'if' or 'unless' dependencies
        next unless dependencies_met?(block, 'if') && dependencies_met?(block, 'unless')

        if new_week.nil? || (!new_week.blocks.blank? && week_finished)
          new_week = Week.create(course_id: @course.id)
          week_finished = false
        end
        block['week_id'] = new_week.id
        block['order'] = i

        if block.key?('graded') && block['graded']
          gradeable = {
            points: block['points'] || 10,
            gradeable_item_type: 'block',
            title: ''
          }
        end

        block = Block.create(block.except('if', 'unless', 'graded', 'points'))

        next if gradeable.nil?

        gradeable['gradeable_item_id'] = block.id
        gradeable = Gradeable.create(gradeable)
        block.update(gradeable_id: gradeable.id)
      end
      week_finished = true
    end
  end

  def dependencies_met?(block, type)
    met = !block.key?(type)
    block_dep = [block_dep] unless block_dep.is_a?(Array)
    met ||= block_dep.reduce(true) do |met, dep|
      met && @logic.include?(dep)
    end

    met
  end

  def add_tags
    @tags.each do |tag|
      if Tag.exists?(course_id: @course.id, key: tag[:key])
        tag_model = Tag.find_by(course_id: @course.id, key: tag[:key])
        tag_model.update(tag: tag[:tag])
      else
        Tag.create(course_id: @course.id, tag: tag[:tag], key: tag[:key])
      end
    end
  end
end
