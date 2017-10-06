# frozen_string_literal: true
# frozen_string_literal: true

#= Creates a new Media record in Salesforce, returning the URL of the new record
class CreateSalesforceMediaRecord
  include ArticleHelper

  def initialize(article:, course:, user:, before_rev_id:, after_rev_id:)
    return unless Features.wiki_ed?
    @article, @course, @user = article, course, user
    @before_rev_id, @after_rev_id = before_rev_id, after_rev_id
    @salesforce_course_id = @course.flags[:salesforce_id]
    @client = Restforce.new
    create_salesforce_record
  end

  def url
    ENV['SF_SERVER'] + @salesforce_media_id
  end

  private

  def create_salesforce_record
    # :create returns the Salesforce id of the new record
    @salesforce_media_id = @client.create!('Media__c', salesforce_media_fields)
  end

  def salesforce_media_fields
    {
      Name: @article.full_title,
      Format__c: 'Wiki Contribution',
      Author_Wiki_Username_Optional__c: @user.username,
      Primary_Course__c: @salesforce_course_id,
      Link__c: @article.url,
      Before_link__c: diff_link(@before_rev_id),
      After_link__c: diff_link(@after_rev_id)
    }
  end

  def diff_link(rev_id)
    return nil if rev_id == '0'
    @article.url + "?oldid=#{rev_id}"
  end
end
