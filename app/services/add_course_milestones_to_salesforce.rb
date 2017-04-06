# frozen_string_literal: true

class AddCourseMilestonesToSalesforce
  attr_reader :result

  def initialize(course)
    return unless Features.wiki_ed?
    @course = course
    @salesforce_id = @course.flags[:salesforce_id]
    @client = Restforce.new
    add_milestones
  end

  private

  def add_milestones
    create_editing_in_sandbox_milestone
    create_editing_in_mainspace_milestone
  end

  def create_editing_in_sandbox_milestone
    return unless editing_in_sandbox_block.present?
    fields = {
      Course__c: @salesforce_id,
      Type__c: 'Editing in Sandbox',
      Start_Date__c: editing_in_sandbox_block.calculated_date.strftime('%Y-%m-%d'),
      Due_Date__c: editing_in_sandbox_block.calculated_due_date.strftime('%Y-%m-%d')
    }
    @client.create!('Milestone__c', fields)
  end

  def editing_in_sandbox_block
    @sandbox_block ||= @course.blocks.find { |block| block.title =~ /Draft your article/ }
  end

  def create_editing_in_mainspace_milestone
    return unless editing_in_mainspace_block.present?
    fields = {
      Course__c: @salesforce_id,
      Type__c: 'Editing in Mainspace',
      Start_Date__c: editing_in_mainspace_block.calculated_date.strftime('%Y-%m-%d'),
      Due_Date__c: editing_in_mainspace_block.calculated_due_date.strftime('%Y-%m-%d')
    }
    @client.create!('Milestone__c', fields)
  end

  def editing_in_mainspace_block
    @mainspace_block ||= @course.blocks.find { |block| block.title =~ /Begin moving your work to Wikipedia/ }
  end
end
