# frozen_string_literal: true

# Phase 0 of PLAN.md: build a sanitized copy of a production dump.
#
# Reads the raw dump database (WCP_RAW_DB) and writes an allowlisted,
# scrubbed copy to WCP_SANITIZED_DB. Only the tables and columns in TABLES are
# copied; anything else in the dump is left behind. Real names and emails are
# dropped, and course, week and block free text has the real names and emails
# of course participants and Wiki Education staff replaced with role tokens.
# Usernames are kept as-is. Private courses keep their counts and structure but
# lose free text.
#
# Output is counts and schema names only; no database value is ever printed.
# Run it yourself (not through an AI agent) with the operator database user —
# see README.md:
#
#   WCP_DB_PASSWORD=... bundle exec ruby docs/analytics_scripts/whole_class_projects/sanitize.rb
#
# Set WCP_REBUILD=1 to drop and rebuild an existing sanitized database.

require_relative 'wcp_common'

TABLES = {
  'courses' => %w[id created_at updated_at start end school title term character_sum view_sum
                  user_count article_count revision_count slug subject expected_students
                  description submitted timeline_start timeline_end day_exceptions weekdays
                  new_article_count no_day_exceptions trained_count cloned_status type
                  upload_count uploads_in_use_count upload_usages_count home_wiki_id
                  recent_revision_count needs_update level private withdrawn references_count],
  'courses_users' => %w[id created_at updated_at course_id user_id character_sum_ms
                        character_sum_us revision_count assigned_article_title role
                        recent_revisions character_sum_draft total_uploads references_count
                        retained_after_course retained_after_course_checked_at],
  'users' => %w[id username global_id created_at updated_at trained permissions onboarded
                greeted greeter locale registered_at first_login],
  'assignments' => %w[id created_at updated_at user_id course_id article_id article_title role
                      wiki_id sandbox_url],
  'articles' => %w[id title created_at updated_at views_updated_at namespace rating
                   rating_updated_at deleted language average_views average_views_updated_at
                   wiki_id mw_page_id],
  'articles_courses' => %w[id created_at updated_at article_id course_id view_count
                           character_sum new_article references_count tracked user_ids
                           first_revision average_views average_views_updated_at],
  'article_course_timeslices' => %w[id course_id article_id start end character_sum
                                    references_count revision_count user_ids new_article tracked
                                    created_at updated_at first_revision],
  'article_course_user_wiki_timeslices' => %w[id article_id character_sum course_id created_at
                                              end first_revision needs_update new_article
                                              references_count revision_count start stats
                                              tracked updated_at user_id wiki_id],
  'course_user_wiki_timeslices' => %w[id course_id user_id wiki_id start end character_sum_ms
                                      character_sum_us character_sum_draft references_count
                                      revision_count created_at updated_at],
  'course_wiki_timeslices' => %w[id course_id wiki_id start end character_sum references_count
                                 revision_count stats last_mw_rev_datetime needs_update
                                 needs_reaggregation created_at updated_at mw_rev_count],
  'weeks' => %w[id title course_id created_at updated_at order],
  'blocks' => %w[id kind content week_id created_at updated_at title order due_date
                 training_module_ids points],
  'campaigns' => %w[id title slug created_at updated_at start end default_course_type],
  'campaigns_courses' => %w[id campaign_id course_id created_at updated_at],
  'courses_wikis' => %w[id course_id wiki_id created_at updated_at],
  'wikis' => %w[id language project],
  'course_wiki_namespaces' => %w[id namespace courses_wikis_id created_at updated_at],
  'tags' => %w[id course_id tag key created_at updated_at],
  'alerts' => %w[id course_id user_id article_id revision_id type email_sent_at created_at
                 updated_at target_user_id subject_id resolved],
  'revision_ai_scores' => %w[id revision_id wiki_id course_id user_id article_id
                             revision_datetime avg_ai_likelihood max_ai_likelihood check_type
                             created_at updated_at check_origin origin_user_id sample_id],
  'training_modules' => %w[id name slug kind created_at updated_at],
  'training_modules_users' => %w[id user_id training_module_id completed_at created_at
                                 updated_at],
  'categories' => %w[id wiki_id name depth source created_at updated_at],
  'categories_courses' => %w[id category_id course_id created_at updated_at]
}.freeze

# Columns copied as NULL and filled in afterwards by scrubbing, so raw values never land in the sanitized database, even briefly.
SELECT_OVERRIDES = {
  'courses' => { 'title' => 'NULL', 'slug' => 'NULL', 'description' => 'NULL' },
  'weeks' => { 'title' => 'NULL' },
  'blocks' => { 'title' => 'NULL', 'content' => 'NULL' }
}.freeze

HONORIFICS = '(?:Prof|Professor|Dr|Mr|Ms|Mrs|Mx|Dean|Instructor)\.?[\s_]+'
BATCH_SIZE = 2000

# The real names and emails to replace with one set of tokens.
class NeedleSet
  attr_reader :skipped_dictionary

  def initialize
    @literal = {}
    @titled = {}
    @first_tokens = Set.new
    @skipped_dictionary = 0
  end

  # name_tokens: also replace individual name parts (for instructors,
  # volunteers and staff, who are often referred to by surname alone).
  # Dictionary-word parts are replaced only after an honorific ("Dr. Young").
  def add_person(person, token, name_tokens:)
    person[:emails].each { |email| add(email, token) }
    person[:names].each do |name|
      add_unless_dictionary(name, token)
      next unless name_tokens

      Wcp.tokens(name).select { |part| part.length >= 3 }.each do |part|
        if Wcp.dictionary.include?(part)
          @titled[part] ||= token
        else
          add(part, token)
        end
      end
    end
  end

  def empty?
    @literal.empty? && @titled.empty?
  end

  def apply(text, counts)
    return text if empty? || !relevant?(text)

    out = text.gsub(literal_regex) do |match|
      counts[:names] += 1
      @literal[match.downcase] || '[NAME]'
    end
    return out if @titled.empty?

    out.gsub(titled_regex) do
      counts[:names] += 1
      "#{Regexp.last_match(1)}#{@titled[Regexp.last_match(2).downcase] || '[NAME]'}"
    end
  end

  private

  def add_unless_dictionary(value, token)
    return @skipped_dictionary += 1 if Wcp.dictionary_word?(value)

    add(value, token)
  end

  def add(value, token)
    needle = value.to_s.strip.squeeze(' ')
    return if needle.length < 3

    [needle, needle.tr(' ', '_'), needle.tr('_', ' ')].each do |form|
      @literal[form.downcase] ||= token
      @first_tokens << Wcp.tokens(form).first
    end
  end

  # Cheap pre-check so the big staff regex only runs on text that could match.
  def relevant?(text)
    toks = Wcp.tokens(text)
    toks.any? { |tok| @first_tokens.include?(tok) || @titled.key?(tok) }
  end

  def literal_regex
    @literal_regex ||= begin
      alternation = @literal.keys.sort_by { |key| -key.length }.map { |key| Regexp.escape(key) }
      Regexp.new("(?<![[:alnum:]])(?:#{alternation.join('|')})(?![[:alnum:]])", Regexp::IGNORECASE)
    end
  end

  def titled_regex
    @titled_regex ||= begin
      alternation = @titled.keys.map { |key| Regexp.escape(key) }.join('|')
      Regexp.new("(?<![[:alnum:]])(#{HONORIFICS})(#{alternation})(?![[:alnum:]])",
                 Regexp::IGNORECASE)
    end
  end
end

class Sanitizer
  def initialize
    @raw = Wcp.client(Wcp::RAW_DB)
    @raw_stream = Wcp.client(Wcp::RAW_DB)
    @san = Wcp.client(Wcp::SANITIZED_DB)
  end

  def run
    abort 'WCP_RAW_DB and WCP_SANITIZED_DB must differ.' if Wcp::RAW_DB == Wcp::SANITIZED_DB
    prepare_target
    verify_allowlist
    @copy_columns.each_key { |table| copy_table(table) }
    scrub_free_text
    record_completion
    puts "\nDone. Next: run audit_sanitized.rb before granting anyone access to #{Wcp::SANITIZED_DB}."
  end

  private

  def prepare_target
    existing = @san.query('SHOW TABLES').map { |row| row.values.first }
    return if existing.empty?
    abort "#{Wcp::SANITIZED_DB} is not empty; set WCP_REBUILD=1 to rebuild it." unless ENV['WCP_REBUILD'] == '1'

    @san.query('SET FOREIGN_KEY_CHECKS = 0')
    existing.each { |table| @san.query("DROP TABLE `#{table}`") }
    @san.query('SET FOREIGN_KEY_CHECKS = 1')
    puts "Dropped #{existing.length} existing tables from #{Wcp::SANITIZED_DB}."
  end

  def raw_columns
    @raw_columns ||= begin
      rows = @raw.query(<<~SQL)
        SELECT TABLE_NAME, COLUMN_NAME, EXTRA FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = '#{@raw.escape(Wcp::RAW_DB)}'
      SQL
      rows.each_with_object(Hash.new { |h, k| h[k] = {} }) do |row, columns|
        generated = row['EXTRA'].to_s.match?(/GENERATED|VIRTUAL|PERSISTENT|STORED/i)
        columns[row['TABLE_NAME']][row['COLUMN_NAME']] = generated
      end
    end
  end

  # Allowlisted columns or tables the dump lacks are skipped with a warning:
  # copying less is always safe.
  def verify_allowlist
    @copy_columns = {}
    TABLES.each do |table, columns|
      next puts("WARNING: table #{table} not in dump; skipped") unless raw_columns.key?(table)

      missing = columns.reject { |column| raw_columns[table].key?(column) }
      puts "WARNING: #{table} lacks #{missing.join(', ')}; skipped" unless missing.empty?
      @copy_columns[table] = columns - missing
    end

    left_behind = raw_columns.keys - TABLES.keys
    puts "Raw tables not copied: #{left_behind.length} (#{left_behind.sort.join(', ')})"
  end

  def copy_table(table)
    columns = @copy_columns[table]
    @san.query("CREATE TABLE `#{table}` LIKE `#{Wcp::RAW_DB}`.`#{table}`")
    relax_unique_indexes(table)
    dropped = raw_columns[table].reject { |col, generated| generated || columns.include?(col) }.keys
    unless dropped.empty?
      @san.query("ALTER TABLE `#{table}` #{dropped.map { |col| "DROP COLUMN `#{col}`" }.join(', ')}")
    end
    insert_rows(table, columns)
    note = dropped.empty? ? '' : "; dropped columns: #{dropped.join(', ')}"
    puts "#{table}: #{@san.affected_rows} rows#{note}"
  end

  # Scrubbed values need not stay unique, and dropping a column from
  # a composite unique index would otherwise narrow it.
  def relax_unique_indexes(table)
    unique = @san.query("SHOW INDEX FROM `#{table}`")
                 .select { |row| row['Non_unique'].to_i.zero? && row['Key_name'] != 'PRIMARY' }
                 .group_by { |row| row['Key_name'] }
    unique.each do |name, parts|
      cols = parts.sort_by { |part| part['Seq_in_index'] }.map do |part|
        part['Sub_part'] ? "`#{part['Column_name']}`(#{part['Sub_part']})" : "`#{part['Column_name']}`"
      end
      @san.query("ALTER TABLE `#{table}` DROP INDEX `#{name}`, ADD INDEX `#{name}` (#{cols.join(', ')})")
    end
  end

  def insert_rows(table, columns)
    overrides = SELECT_OVERRIDES.fetch(table, {})
    select = columns.map { |col| overrides[col] || "`#{col}`" }
    @san.query(<<~SQL)
      INSERT INTO `#{table}` (#{columns.map { |col| "`#{col}`" }.join(', ')})
      SELECT #{select.join(', ')} FROM `#{Wcp::RAW_DB}`.`#{table}`
    SQL
  end

  def update_in_batches(sql, rows)
    statement = @san.prepare(sql)
    count = 0
    @san.query('START TRANSACTION')
    rows.each do |row|
      params = yield(row)
      next if params.nil?

      statement.execute(*params)
      count += 1
      next unless (count % BATCH_SIZE).zero?

      @san.query('COMMIT')
      @san.query('START TRANSACTION')
    end
    @san.query('COMMIT')
    count
  end

  # --- Free-text scrubbing ---------------------------------------------------

  def scrub_free_text
    load_people
    private_ids = @raw.query('SELECT id FROM courses WHERE private = 1').map { |row| row['id'] }.to_set
    counts = Hash.new(0)

    rows = @raw_stream.query('SELECT id, title, slug, description FROM courses', stream: true, cache_rows: false)
    update_in_batches('UPDATE courses SET title = ?, slug = ?, description = ? WHERE id = ?', rows) do |row|
      next [nil, nil, nil, row['id']] if private_ids.include?(row['id'])

      sets = needle_sets(row['id'])
      [scrub(row['title'], sets, counts), scrub(row['slug'], sets, counts),
       scrub(row['description'], sets, counts), row['id']]
    end
    report('courses', counts)

    counts = Hash.new(0)
    rows = @raw_stream.query('SELECT id, course_id, title FROM weeks', stream: true, cache_rows: false)
    week_courses = {}
    update_in_batches('UPDATE weeks SET title = ? WHERE id = ?', rows) do |row|
      week_courses[row['id']] = row['course_id']
      next [nil, row['id']] if private_ids.include?(row['course_id'])

      [scrub(row['title'], needle_sets(row['course_id']), counts), row['id']]
    end
    report('weeks', counts)

    counts = Hash.new(0)
    rows = @raw_stream.query('SELECT id, week_id, title, content FROM blocks', stream: true, cache_rows: false)
    update_in_batches('UPDATE blocks SET title = ?, content = ? WHERE id = ?', rows) do |row|
      course_id = week_courses[row['week_id']]
      next [nil, nil, row['id']] if private_ids.include?(course_id)

      sets = needle_sets(course_id)
      [scrub(row['title'], sets, counts), scrub(row['content'], sets, counts), row['id']]
    end
    report('blocks', counts)
    puts "Dictionary-word names not used as needles: #{@skipped_dictionary}"
  end

  def load_people
    @course_people = Hash.new { |h, k| h[k] = {} }
    staff = {}
    rows = @raw_stream.query(<<~SQL, stream: true, cache_rows: false)
      SELECT cu.course_id, cu.user_id, cu.role, cu.real_name AS course_name,
             u.real_name, u.email, u.permissions
      FROM courses_users cu JOIN users u ON u.id = cu.user_id
    SQL
    rows.each do |row|
      person = (@course_people[row['course_id']][row['user_id']] ||= new_person(row['role']))
      person[:role] = [person[:role], row['role'].to_i].max
      add_identity(person, row)
      add_identity(staff[row['user_id']] ||= new_person(4), row) if staff_row?(row)
    end
    @raw.query("SELECT real_name, email FROM users WHERE permissions IN (#{Wcp::STAFF_PERMISSIONS.join(', ')})")
        .each_with_index { |row, i| add_identity(staff["admin#{i}"] ||= new_person(4), row) }
    @staff_needles = NeedleSet.new
    staff.each_value { |person| @staff_needles.add_person(person, '[STAFF]', name_tokens: true) }
    @skipped_dictionary = @staff_needles.skipped_dictionary
    @course_needles = {}
    @counted_courses = Set.new
    puts "Loaded participants for #{@course_people.length} courses and #{staff.length} staff identities"
  end

  def staff_row?(row)
    row['role'].to_i == 4 || Wcp::STAFF_PERMISSIONS.include?(row['permissions'].to_i)
  end

  def new_person(role)
    { role: role.to_i, names: Set.new, emails: Set.new }
  end

  def add_identity(person, row)
    [row['real_name'], row['course_name']].each do |name|
      person[:names] << name if name.to_s.strip != ''
    end
    person[:emails] << row['email'] if row['email'].to_s.strip != ''
  end

  def needle_sets(course_id)
    [course_needles(course_id), @staff_needles]
  end

  def course_needles(course_id)
    return NeedleSet.new if course_id.nil?

    @course_needles.shift if @course_needles.length > 500
    @course_needles[course_id] ||= build_course_needles(course_id)
  end

  def build_course_needles(course_id)
    set = NeedleSet.new
    numbering = Hash.new(0)
    @course_people.fetch(course_id, {}).sort.each do |_user_id, person|
      label = Wcp::ROLE_TOKENS.fetch(person[:role], 'PARTICIPANT')
      numbering[label] += 1
      set.add_person(person, "[#{label}_#{numbering[label]}]", name_tokens: person[:role].positive?)
    end
    @skipped_dictionary += set.skipped_dictionary if @counted_courses.add?(course_id)
    set
  end

  def scrub(text, sets, counts)
    return text if text.nil? || text.empty?

    out = text.gsub(Wcp::EMAIL_RE) { counts[:emails] += 1; '[EMAIL]' }
    sets.each { |set| out = set.apply(out, counts) }
    out.gsub(Wcp::PHONE_RE) { counts[:phones] += 1; '[PHONE]' }
  end

  def report(table, counts)
    summary = %i[names emails phones].map { |kind| "#{kind}=#{counts[kind]}" }.join(', ')
    puts "#{table}: replacements #{summary}"
  end

  def record_completion
    @san.query('CREATE TABLE _sanitization_status (completed_at DATETIME, raw_database VARCHAR(64))')
    @san.query("INSERT INTO _sanitization_status VALUES (NOW(), '#{@san.escape(Wcp::RAW_DB)}')")
  end
end

Wcp.run_safely { Sanitizer.new.run }
