# frozen_string_literal: true

# Phase 1 of PLAN.md: per-course collaboration concentration metrics.
#
# For every Classroom Program course, measures how concentrated student work
# is on a few articles, two ways:
#
# - assign_*: from role-0 (assigned editing) assignments of enrolled students
#   to mainspace or draft articles (or not-yet-existing titles). Covers 2015+.
# - edit_*: from articles_courses.user_ids for tracked mainspace articles the
#   course's students actually edited (character_sum > 0). Only populated for
#   courses from 2020 on.
#
# For each signal:
#   students      students with at least one assignment / edited article
#   articles      distinct articles
#   top1_share    share of those students on the single most-shared article
#   top3_share    share covered by the three most-shared articles
#   median_group  median over students of the size of the biggest group they
#                 belong to (1 = worked alone). Inflated by shared exercise
#                 articles done alongside individual ones.
#   only_top3     share of students whose every assignment/edited article is
#                 among the top three (robust to shared exercise articles)
#
# And from articles_courses.character_sum (2015+, all tracked mainspace
# articles): char_top1_share / char_top3_share, the share of the course's
# mainspace characters added that went to its one / three biggest articles.
#
# Also defines the wcp_analysis.collab_mode view (the rule-based mode label)
# and wcp_analysis.block_content_spread (how many courses share each timeline
# block's exact content; spread > 3 is Wiki Ed template text).
#
# Reads wcp_sanitized, writes wcp_analysis.course_collab_metrics and
# data/course_collab_metrics.csv. Run as the wiki user:
#
#   WCP_DB_USER=wiki WCP_DB_PASSWORD=wikiedu bundle exec ruby \
#     docs/analytics_scripts/whole_class_projects/phase1_collab_metrics.rb

require 'csv'
require_relative 'wcp_common'

ANALYSIS_DB = ENV.fetch('WCP_ANALYSIS_DB', 'wcp_analysis')
OUTPUT_CSV = File.expand_path('data/course_collab_metrics.csv', __dir__)
COURSE_COLUMNS = %w[id start end term school subject level user_count expected_students].freeze
SIGNAL_COLUMNS = %w[students articles top1_share top3_share median_group only_top3].freeze
CHAR_COLUMNS = %w[char_total char_articles char_top1_share char_top3_share].freeze

class CollabMetrics
  def initialize
    @db = Wcp.client(Wcp::SANITIZED_DB)
  end

  def run
    courses = load_courses
    students = load_students
    assign = group_sets(assignment_groups, students)
    edit = group_sets(edit_groups, students)
    chars = char_concentration
    rows = courses.map do |course|
      id = course['id']
      course.merge('enrolled_students' => students.fetch(id, Set.new).size)
            .merge(signal('assign', assign[id]))
            .merge(signal('edit', edit[id]))
            .merge(chars.fetch(id, { 'char_total' => 0 }))
    end
    write_csv(rows)
    write_table(rows)
    create_derived
    puts "Wrote #{rows.length} courses to #{OUTPUT_CSV} and #{ANALYSIS_DB}.course_collab_metrics"
  end

  private

  def load_courses
    @db.query(<<~SQL).to_a
      SELECT #{COURSE_COLUMNS.map { |col| "`#{col}`" }.join(', ')} FROM courses
      WHERE type = 'ClassroomProgramCourse' AND withdrawn = 0
      ORDER BY start
    SQL
  end

  def load_students
    @db.query('SELECT course_id, user_id FROM courses_users WHERE role = 0')
       .each_with_object(Hash.new { |h, k| h[k] = Set.new }) do |row, by_course|
      by_course[row['course_id']] << row['user_id']
    end
  end

  # [course_id, article_key, user_id] rows
  def assignment_groups
    @db.query(<<~SQL, stream: true, cache_rows: false).map { |row| [row['course_id'], row['k'], row['user_id']] }
      SELECT s.course_id, s.user_id,
             COALESCE(CONCAT('a', s.article_id), CONCAT('t', s.wiki_id, ':', LOWER(s.article_title))) AS k
      FROM assignments s LEFT JOIN articles a ON a.id = s.article_id
      WHERE s.role = 0 AND (s.article_id IS NULL OR a.namespace IN (0, 118))
    SQL
  end

  def edit_groups
    rows = @db.query(<<~SQL, stream: true, cache_rows: false)
      SELECT ac.course_id, ac.article_id, ac.user_ids
      FROM articles_courses ac JOIN articles a ON a.id = ac.article_id
      WHERE ac.tracked = 1 AND ac.character_sum > 0 AND a.namespace = 0 AND ac.user_ids IS NOT NULL
    SQL
    rows.flat_map do |row|
      row['user_ids'].scan(/\d+/).map { |uid| [row['course_id'], row['article_id'], uid.to_i] }
    end
  end

  def char_concentration
    rows = @db.query(<<~SQL)
      SELECT ac.course_id, ac.character_sum FROM articles_courses ac JOIN articles a ON a.id = ac.article_id
      WHERE ac.tracked = 1 AND ac.character_sum > 0 AND a.namespace = 0
    SQL
    rows.group_by { |row| row['course_id'] }.transform_values do |course_rows|
      sums = course_rows.map { |row| row['character_sum'] }.sort.reverse
      total = sums.sum.to_f
      { 'char_total' => total.to_i, 'char_articles' => sums.size,
        'char_top1_share' => (sums.first / total).round(3),
        'char_top3_share' => (sums.first(3).sum / total).round(3) }
    end
  end

  # course_id => { article_key => Set[user_id] }, enrolled students only
  def group_sets(triples, students)
    triples.each_with_object(Hash.new { |h, k| h[k] = Hash.new { |g, a| g[a] = Set.new } }) do |(cid, key, uid), acc|
      acc[cid][key] << uid if students.fetch(cid, Set.new).include?(uid)
    end
  end

  def signal(prefix, groups)
    groups = (groups || {}).reject { |_key, members| members.empty? }
    members = groups.values.reduce(Set.new, :|)
    return SIGNAL_COLUMNS.to_h { |col| ["#{prefix}_#{col}", col == 'students' ? 0 : nil] } if members.empty?

    ranked = groups.values.sort_by { |set| -set.size }
    biggest = members.map { |uid| ranked.find { |set| set.include?(uid) }.size }.sort
    top3 = ranked.first(3).reduce(Set.new, :|)
    outside = ranked.drop(3).reduce(Set.new, :|)
    {
      "#{prefix}_students" => members.size,
      "#{prefix}_articles" => groups.size,
      "#{prefix}_top1_share" => (ranked.first.size.to_f / members.size).round(3),
      "#{prefix}_top3_share" => (top3.size.to_f / members.size).round(3),
      "#{prefix}_median_group" => biggest[biggest.size / 2],
      "#{prefix}_only_top3" => ((top3 - outside).size.to_f / members.size).round(3)
    }
  end

  # Rule-based mode, before LLM review. Whole-class: >=75% of assigned students
  # work only on the top 3 articles, and the median student's group is at least
  # 5 and at least 30% of the class.
  MODE_VIEW = <<~SQL
    CREATE OR REPLACE VIEW collab_mode AS SELECT *,
      CASE
        WHEN assign_students >= 6 AND assign_only_top3 >= 0.75
             AND assign_median_group >= GREATEST(5, 0.3 * assign_students) THEN 'whole_class'
        WHEN assign_students >= 6 AND assign_median_group BETWEEN 2 AND 5 THEN 'small_group'
        WHEN assign_students >= 6 AND assign_median_group = 1 THEN 'individual'
        WHEN assign_students >= 6 THEN 'other'
        ELSE 'insufficient'
      END AS mode_rule
    FROM course_collab_metrics
  SQL

  def create_derived
    out = Wcp.client(ANALYSIS_DB)
    out.query(MODE_VIEW)
    out.query('DROP TABLE IF EXISTS block_content_spread')
    out.query(<<~SQL)
      CREATE TABLE block_content_spread (h CHAR(64) PRIMARY KEY, nc INT) AS
      SELECT SHA2(b.content, 256) AS h, COUNT(DISTINCT w.course_id) AS nc
      FROM #{Wcp::SANITIZED_DB}.blocks b JOIN #{Wcp::SANITIZED_DB}.weeks w ON w.id = b.week_id
      WHERE b.content IS NOT NULL AND b.content <> '' GROUP BY h
    SQL
  end

  def headers
    COURSE_COLUMNS + ['enrolled_students'] +
      %w[assign edit].flat_map { |prefix| SIGNAL_COLUMNS.map { |col| "#{prefix}_#{col}" } } +
      CHAR_COLUMNS
  end

  def write_csv(rows)
    CSV.open(OUTPUT_CSV, 'w') do |csv|
      csv << headers
      rows.each { |row| csv << headers.map { |h| row[h] } }
    end
  end

  def write_table(rows)
    out = Wcp.client(ANALYSIS_DB)
    out.query('DROP TABLE IF EXISTS course_collab_metrics')
    out.query(<<~SQL)
      CREATE TABLE course_collab_metrics (
        course_id INT PRIMARY KEY, `start` DATETIME, `end` DATETIME, term VARCHAR(255),
        school VARCHAR(255), subject VARCHAR(255), level VARCHAR(255), user_count INT,
        expected_students INT, enrolled_students INT,
        #{%w[assign edit].map do |p|
          "#{p}_students INT, #{p}_articles INT, #{p}_top1_share FLOAT, " \
            "#{p}_top3_share FLOAT, #{p}_median_group INT, #{p}_only_top3 FLOAT"
        end.join(",\n")},
        char_total INT, char_articles INT, char_top1_share FLOAT, char_top3_share FLOAT
      )
    SQL
    statement = out.prepare("INSERT INTO course_collab_metrics VALUES (#{(['?'] * headers.length).join(', ')})")
    out.query('START TRANSACTION')
    rows.each { |row| statement.execute(*headers.map { |h| row[h] }) }
    out.query('COMMIT')
  end
end

Wcp.run_safely { CollabMetrics.new.run }
