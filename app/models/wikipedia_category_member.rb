# frozen_string_literal: true
require_dependency "#{Rails.root}/lib/wiki_api"

class WikipediaCategoryMember < ApplicationRecord
  # Method for fetching categorymembers data from the Wiki API
  def fetch_category_members
    query_params = build_query_params

    response = query_wiki_api(query_params)

    if response&.status == 200
      category_members = response.data['categorymembers'].pluck('title')
      save_category_members(category_members)
    else
      Rails.logger.warn('Failed to fetch categorymembers data')
    end
  end

  private

  # Method for building the query parameters
  def build_query_params
    {
      action: 'query',
      cmtitle: ENV['category_title'],
      cmlimit: 20,
      list: 'categorymembers',
      format: 'json',
      formatversion: '2'
    }
  end

  # Method for querying the Wiki API
  def query_wiki_api(query_params)
    WikiApi.new(Wiki.default_wiki).query(query_params)
  end

  # Method for saving category_members data to the database
  def save_category_members(category_members)
    # Fetch the existing category members from the database
    existing_category_members = WikipediaCategoryMember.pluck(:category_member)

    # Find the members to be added (new members)
    members_to_add = category_members - existing_category_members

    # Find the members to be removed (members in the database but not in the new data)
    members_to_remove = existing_category_members - category_members

    # Remove members that are not in the new data
    WikipediaCategoryMember.where(category_member: members_to_remove).delete_all

    # Add new members to the database
    members_to_add.each do |category_member|
      WikipediaCategoryMember.create(category_member:)
    end
  end
end
