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
    @all_content = YAML.load_file(content_path)
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
    require "#{Rails.root}/lib/course_meetings_manager"
    meeting_manager = CourseMeetingsManager.new(@course)
    available_weeks = meeting_manager.open_weeks

    return [] if available_weeks <= 0

    timeline = initial_weeks_and_weights(content_groups)

    while timeline.size > available_weeks
      timeline = squish_timeline_by_one_week(timeline)
    end
    timeline
  end

  def initial_weeks_and_weights(content_groups)
    content_groups.flatten.map do |week|
      OpenStruct.new(
        weight: week['weight'],
        blocks: week['blocks']
      )
    end
  end

  def squish_timeline_by_one_week(timeline)
    low_weight = 1000 # arbitrarily high number
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

    timeline
  end

  def save_timeline(timeline)
    new_week = nil
    week_finished = false
    timeline.each do |week|
      week[:blocks].each_with_index do |block, i|
        # Skip blocks with unmet 'if' or 'unless' dependencies

        next unless if_dependencies_met?(block)
        # NOTE: uncomment this if/when we use 'unless' blocks in the wizard,
        # and be sure to add tests.
        # next unless unless_dependencies_met?(block)

        if new_week.nil? || (!new_week.blocks.blank? && week_finished)
          new_week = Week.create(course_id: @course.id)
          week_finished = false
        end
        save_block_and_gradeable(new_week, block, i)
      end
      week_finished = true
    end
  end

  def if_dependencies_met?(block)
    if_met = !block.key?('if')
    if_met ||= Array.wrap(block['if']).reduce(true) do |met, dep|
      met && @logic.include?(dep)
    end
    if_met
  end

  # def unless_dependencies_met?(block)
  #   # Skip blocks with unmet 'unless' dependencies
  #   unless_met = !block.key?('unless')
  #   block_unless = block['unless']
  #   block_unless = [block_unless] unless block_unless.is_a?(Array)
  #
  #   unless_met ||= block_unless.reduce(true) do |met, dep|
  #     met && !@logic.include?(dep)
  #   end
  #   unless_met
  # end

  def save_block_and_gradeable(week, block, i)
    block['week_id'] = week.id
    block['order'] = i

    if block.key?('graded') && block['graded']
      gradeable_params = {
        points: block['points'] || 10,
        gradeable_item_type: 'block',
        title: ''
      }
    end

    attr_keys_to_skip = %w(if unless graded points)
    block_params = block.except(*attr_keys_to_skip)
    block = Block.create(block_params)

    return if gradeable_params.nil?

    gradeable_params['gradeable_item_id'] = block.id
    gradeable = Gradeable.create(gradeable_params)
    block.update(gradeable_id: gradeable.id)
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
