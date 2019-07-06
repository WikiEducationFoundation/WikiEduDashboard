# frozen_string_literal: true

require 'csv'

class CourseRevisionsCsvBuilder
  def initialize(course)
    @course = course
    set_revisions
  end

  def generate_csv
    csv_data = [CSV_HEADERS]
    revisions_rows.each do |row|
      csv_data << row
    end
    CSV.generate { |csv| csv_data.each { |line| csv << line } }
  end

  def revisions_rows
    @new_revisions.values.map do |revision_data|
      build_row(revision_data)
    end
  end

  def set_revisions
    @new_revisions = {}
    @course.all_revisions.includes(article: :wiki).map do |edit|
      revision_edits = @new_revisions[edit.article_id] || new_revision(edit)
      revision_edits[:mw_rev_id] = edit.mw_rev_id
      revision_edits[:mw_page_id] = edit.mw_page_id
      revision_edits[:wiki_id] = edit.wiki_id
      update_characters_references_views(revision_edits, edit)
      revision_edits[:new_article] = true if edit.new_article
      revision_edits[:deleted] = true if edit.deleted
      revision_edits[:wp10] = edit.wp10
      revision_edits[:wp10_previous] = edit.wp10_previous
      @new_revisions[edit.article_id] = revision_edits
    end
  end

  def new_revision(edit)
    {
      new_article: false,
      views: 0,
      characters: {},
      references: {},
      deleted: edit.deleted,
      wp10: {},
      wp10_previous: {},
      article_id: edit.article_id
    }
  end

  def update_characters_references_views(revision_edits, edit)
    revision_edits[:characters] = edit.characters
    revision_edits[:references] = edit.references_added
    revision_edits[:views] = edit.views
  end

  CSV_HEADERS = %w[
    revision_id
    page_id
    wiki
    characters_added
    references_added
    new
    article_id
    pageviews
    deleted
    wp10
    wp10_previous
  ].freeze

  def build_row(revision_data)
    row = [revision_data[:mw_rev_id]]
    row << revision_data[:page_id]
    row << revision_data[:wiki_id]
    row << revision_data[:wiki_domain]
    add_characters_references(revision_data, row)
    row << revision_data[:new_article]
    row << revision_data[:article_id]
    row << revision_data[:deleted]
    row << revision_data[:views]
    row << revision_data[:wp10]
    row << revision_data[:wp10_previous]
  end

  def add_characters_references(revision_data, row)
    row << revision_data[:characters]
    row << revision_data[:references]
  end
end
