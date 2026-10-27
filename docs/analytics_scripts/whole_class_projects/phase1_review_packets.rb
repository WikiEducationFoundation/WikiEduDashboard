# frozen_string_literal: true

# Phase 1 of PLAN.md: build LLM review packets for collaboration-mode labels.
#
# Selects courses from wcp_analysis.collab_mode (defined by
# phase1_collab_metrics.rb) into these pools:
#
#   rule_whole_class   the metric rule says whole-class
#   near_miss          >=50% of students only on the top 3 articles and median
#                      group >= 4, but not whole-class by rule
#   other              >=6 assigned students, large median groups, unclear
#   edit_only_whole    too few assignments, but edit data says whole-class
#   no_editor_data     >=6 students, no assignment or editor data, >=80% of
#                      mainspace characters on one article
#   control_small      random sample of rule small_group courses
#   control_individual random sample of rule individual courses
#
# Each packet has course metadata, the (sanitized) description, custom
# timeline text (blocks whose content appears in at most 3 courses, i.e. not
# Wiki Ed template text), the top assigned and edited articles, and metrics.
# Writes data/phase1_review_packets.jsonl.

require 'json'
require_relative 'wcp_common'

OUTPUT = File.expand_path('data/phase1_review_packets.jsonl', __dir__)
CONTROL_SIZE = 40
CUSTOM_TEXT_LIMIT = 4000
DESCRIPTION_LIMIT = 3000

POOLS = {
  'rule_whole_class' => "mode_rule = 'whole_class'",
  'near_miss' => "mode_rule <> 'whole_class' AND assign_students >= 6 AND assign_only_top3 >= 0.5 " \
                 'AND assign_median_group >= 4',
  'other' => "mode_rule = 'other'",
  'edit_only_whole' => "mode_rule = 'insufficient' AND edit_students >= 6 AND edit_only_top3 >= 0.75 " \
                       'AND edit_median_group >= GREATEST(5, 0.3 * edit_students)',
  'no_editor_data' => "mode_rule = 'insufficient' AND enrolled_students >= 6 AND COALESCE(edit_students, 0) < 6 " \
                      'AND char_total > 0 AND char_top1_share >= 0.8',
  'control_small' => "mode_rule = 'small_group' ORDER BY RAND(20260929) LIMIT #{CONTROL_SIZE}",
  'control_individual' => "mode_rule = 'individual' ORDER BY RAND(20260929) LIMIT #{CONTROL_SIZE}"
}.freeze

METRICS = %w[enrolled_students assign_students assign_articles assign_top1_share assign_top3_share
             assign_median_group assign_only_top3 edit_students edit_articles edit_top1_share
             edit_top3_share edit_median_group edit_only_top3 char_total char_articles
             char_top1_share char_top3_share].freeze

class ReviewPackets
  def initialize
    @db = Wcp.client('wcp_analysis')
  end

  def run
    seen = Set.new
    count = 0
    File.open(OUTPUT, 'w') do |out|
      POOLS.each do |pool, where|
        ids = @db.query("SELECT course_id FROM collab_mode WHERE #{where}").map { |row| row['course_id'] }
        fresh = ids.reject { |id| seen.include?(id) }
        seen.merge(fresh)
        fresh.each { |id| out.puts(JSON.generate(packet(id, pool))) }
        puts "#{pool}: #{fresh.length} courses"
        count += fresh.length
      end
    end
    puts "Wrote #{count} packets to #{OUTPUT}"
  end

  private

  def packet(id, pool)
    course = @db.query(<<~SQL).first
      SELECT c.id, c.title, c.school, c.term, c.subject, c.level, c.start, c.end, c.description, m.mode_rule
      FROM wcp_sanitized.courses c JOIN collab_mode m ON m.course_id = c.id WHERE c.id = #{Integer(id)}
    SQL
    {
      course_id: id, pool:, mode_rule: course['mode_rule'],
      title: course['title'], school: course['school'], term: course['term'],
      subject: course['subject'], level: course['level'],
      start: course['start']&.to_date&.iso8601, end: course['end']&.to_date&.iso8601,
      description: course['description'].to_s[0, DESCRIPTION_LIMIT],
      custom_timeline_text: custom_text(id),
      top_assigned_articles: top_assigned(id),
      top_edited_articles: top_edited(id),
      metrics: metrics(id)
    }
  end

  def custom_text(id)
    rows = @db.query(<<~SQL)
      SELECT w.`order` AS week, b.title, b.content FROM wcp_sanitized.blocks b
      JOIN wcp_sanitized.weeks w ON w.id = b.week_id
      WHERE w.course_id = #{Integer(id)} AND b.content IS NOT NULL AND b.content <> ''
        AND SHA2(b.content, 256) IN (
          SELECT h FROM block_content_spread WHERE nc <= 3
        )
      ORDER BY w.`order`, b.`order`
    SQL
    text = rows.map { |row| "[Week #{row['week']}: #{row['title']}] #{row['content']}" }.join("\n")
    text[0, CUSTOM_TEXT_LIMIT]
  end

  def top_assigned(id)
    @db.query(<<~SQL).map { |row| { title: row['title'], students: row['n'] } }
      SELECT COALESCE(a.title, s.article_title) AS title, COUNT(DISTINCT s.user_id) AS n
      FROM wcp_sanitized.assignments s
      JOIN wcp_sanitized.courses_users cu ON cu.course_id = s.course_id AND cu.user_id = s.user_id AND cu.role = 0
      LEFT JOIN wcp_sanitized.articles a ON a.id = s.article_id
      WHERE s.course_id = #{Integer(id)} AND s.role = 0
      GROUP BY COALESCE(CONCAT('a', s.article_id), s.article_title), title
      ORDER BY n DESC LIMIT 8
    SQL
  end

  def top_edited(id)
    rows = @db.query(<<~SQL).to_a
      SELECT a.title, ac.character_sum, ac.user_ids, ac.new_article
      FROM wcp_sanitized.articles_courses ac JOIN wcp_sanitized.articles a ON a.id = ac.article_id
      WHERE ac.course_id = #{Integer(id)} AND ac.tracked = 1 AND ac.character_sum > 0 AND a.namespace = 0
      ORDER BY ac.character_sum DESC
    SQL
    total = rows.sum { |row| row['character_sum'] }.to_f
    rows.first(8).map do |row|
      { title: row['title'], share_of_characters: (row['character_sum'] / total).round(3),
        characters: row['character_sum'], new_article: row['new_article'] == 1,
        student_editors: row['user_ids'] ? row['user_ids'].scan(/\d+/).length : nil }
    end
  end

  def metrics(id)
    row = @db.query("SELECT #{METRICS.join(', ')} FROM collab_mode WHERE course_id = #{Integer(id)}").first
    row.transform_values { |value| value.is_a?(Float) ? value.round(3) : value }
  end
end

Wcp.run_safely { ReviewPackets.new.run }
