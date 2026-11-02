# frozen_string_literal: true

# Phase 0 of PLAN.md: check a sanitized database for leaked private data.
#
# Fails if the sanitized database has private-looking columns (real names,
# emails, tokens and the like) or serialized columns containing @. As a
# warning only, reports every raw real name and email found in the sanitized
# database's text columns. Usernames are deliberately kept and not checked.
#
# Output is counts and schema names only, so it is safe to paste to an AI
# agent. Pass --show to also print the matching values for your own review —
# that output must NOT be pasted anywhere.
#
#   WCP_DB_PASSWORD=... bundle exec ruby docs/analytics_scripts/whole_class_projects/audit_sanitized.rb
#
# Exit status is 0 on PASS, 1 on FAIL.

require_relative 'wcp_common'

class Auditor
  # Scrubbed free text (phone numbers are only counted here).
  FREE_TEXT = {
    'courses' => %w[title slug description],
    'weeks' => %w[title],
    'blocks' => %w[title content]
  }.freeze
  # Serialized counts and id lists; checked by SQL for email and letter
  # content instead of token scanning (these tables are very large).
  MACHINE = {
    'article_course_user_wiki_timeslices' => %w[stats],
    'course_wiki_timeslices' => %w[stats],
    'articles_courses' => %w[user_ids],
    'article_course_timeslices' => %w[user_ids]
  }.freeze
  PRIVATE_COLUMN_RE = /email(?!_sent_at)|real_name|passcode|password|token|secret|chat_|message|details|notes|bio/i
  TEXT_TYPES = %w[char varchar tinytext text mediumtext longtext].freeze
  MAX_NGRAM = 8

  def initialize(show:)
    @show = show
    @raw = Wcp.client(Wcp::RAW_DB)
    @san = Wcp.client(Wcp::SANITIZED_DB)
    @failures = []
    @warnings = []
  end

  def run
    check_completion
    check_schema
    load_needles
    text_columns.each { |table, column| scan_column(table, column) }
    MACHINE.each { |table, cols| cols.each { |col| check_machine_column(table, col) } }
    verdict
  end

  private

  def check_completion
    tables = @san.query('SHOW TABLES').map { |row| row.values.first }
    return if tables.include?('_sanitization_status')

    @failures << 'no _sanitization_status table: sanitize.rb did not finish'
  end

  def columns
    @columns ||= @san.query(<<~SQL).to_a
      SELECT TABLE_NAME AS t, COLUMN_NAME AS c, DATA_TYPE AS type FROM information_schema.COLUMNS
      WHERE TABLE_SCHEMA = '#{@san.escape(Wcp::SANITIZED_DB)}' ORDER BY TABLE_NAME, ORDINAL_POSITION
    SQL
  end

  def check_schema
    puts '== Schema'
    columns.group_by { |row| row['t'] }.each do |table, cols|
      puts "#{table}: #{cols.map { |row| row['c'] }.join(', ')}"
    end
    suspicious = columns.select { |row| row['c'].match?(PRIVATE_COLUMN_RE) }
                        .map { |row| "#{row['t']}.#{row['c']}" }
    @failures << "private-looking columns present: #{suspicious.join(', ')}" unless suspicious.empty?
  end

  # needle (space-joined lowercase tokens) => { kinds: Set, dictionary: bool }
  def load_needles
    @needles = {}
    @first_tokens = Set.new
    @raw.query('SELECT real_name, email FROM users', stream: true, cache_rows: false).each do |row|
      add_needle(row['real_name'], :name)
      add_needle(row['email'], :email)
    end
    @raw.query('SELECT real_name FROM courses_users', stream: true, cache_rows: false).each do |row|
      add_needle(row['real_name'], :name)
    end
    dictionary = @needles.count { |_needle, info| info[:dictionary] }
    puts "\n== Needles: #{@needles.length} distinct (#{dictionary} are single dictionary words)"
  end

  def add_needle(value, kind)
    toks = Wcp.tokens(value)
    return if toks.empty? || toks.length > MAX_NGRAM
    return if toks.join.length < 4 || toks.all? { |tok| tok.match?(/\A\d+\z/) }

    key = toks.join(' ')
    info = (@needles[key] ||= { kinds: Set.new, dictionary: toks.length == 1 && Wcp.dictionary.include?(key) })
    info[:kinds] << kind
    @first_tokens << toks.first
  end

  def text_columns
    skipped = MACHINE
    columns.select { |row| TEXT_TYPES.include?(row['type']) }
           .map { |row| [row['t'], row['c']] }
           .reject { |table, col| table.start_with?('_') || skipped.fetch(table, []).include?(col) }
  end

  def scan_column(table, column)
    stats = { rows: 0, strong: 0, dictionary: 0, emails: 0, phones: 0, distinct: Set.new }
    free_text = FREE_TEXT.fetch(table, []).include?(column)
    id_expr = columns.any? { |row| row['t'] == table && row['c'] == 'id' } ? 'id' : 'NULL'
    rows = @san.query("SELECT #{id_expr} AS id, `#{column}` AS v FROM `#{table}` WHERE `#{column}` IS NOT NULL",
                      stream: true, cache_rows: false)
    rows.each { |row| scan_value(table, column, row, stats, free_text) }
    record_column(table, column, stats, free_text)
  end

  def scan_value(table, column, row, stats, free_text)
    value = row['v'].to_s
    emails = value.scan(Wcp::EMAIL_RE).length
    phones = free_text ? value.scan(Wcp::PHONE_RE).length : 0
    hits = needle_hits(value)
    stats[:emails] += emails
    stats[:phones] += phones
    return if hits.empty? && emails.zero? && phones.zero?

    stats[:rows] += 1
    hits.each do |needle|
      @needles[needle][:dictionary] ? stats[:dictionary] += 1 : stats[:strong] += 1
      stats[:distinct] << needle unless @needles[needle][:dictionary]
    end
    show(table, column, row['id'], hits, value) if @show
  end

  def needle_hits(value)
    toks = Wcp.tokens(value)
    hits = []
    toks.each_index do |i|
      next unless @first_tokens.include?(toks[i])

      (1..MAX_NGRAM).each do |n|
        break if i + n > toks.length

        key = toks[i, n].join(' ')
        hits << key if @needles.key?(key)
      end
    end
    hits
  end

  def record_column(table, column, stats, _free_text)
    label = "#{table}.#{column}"
    puts format('%-55<label>s rows_hit=%<rows>d strong=%<strong>d distinct_strong=%<distinct>d ' \
                'dictionary=%<dict>d emails=%<emails>d phones=%<phones>d',
                label:, rows: stats[:rows], strong: stats[:strong], distinct: stats[:distinct].length,
                dict: stats[:dictionary], emails: stats[:emails], phones: stats[:phones])
    return unless stats[:strong].positive? || stats[:phones].positive? || stats[:emails].positive?

    # Leftover names and emails in text are informational: only the real_name and
    # email columns themselves must be gone (checked in check_schema).
    @warnings << "#{label}: #{stats[:strong]} real-name matches, #{stats[:emails]} email-shaped " \
                 "strings, #{stats[:phones]} phone-shaped strings"
  end

  def check_machine_column(table, column)
    counts = @san.query(<<~SQL).first
      SELECT SUM(`#{column}` LIKE '%@%') AS at_signs,
             SUM(`#{column}` REGEXP '[[:alpha:]]{3,}[[:space:]]+[[:alpha:]]{3,}') AS word_pairs
      FROM `#{table}`
    SQL
    at_signs = counts['at_signs'].to_i
    puts "#{table}.#{column} (SQL check): at_signs=#{at_signs} word_pairs=#{counts['word_pairs'].to_i}"
    @warnings << "#{table}.#{column}: #{at_signs} values containing @" if at_signs.positive?
  end

  def show(table, column, id, hits, value)
    snippet = value.length > 300 ? "#{value[0, 300]}…" : value
    puts "  [SHOW] #{table}.#{column} id=#{id} needles=#{hits.uniq.inspect} value=#{snippet.inspect}"
  end

  def verdict
    puts "\n== Warnings (leftover names and emails in text; review with --show)"
    puts(@warnings.empty? ? 'none' : @warnings)
    puts "\n== Failures"
    puts(@failures.empty? ? 'none' : @failures)
    puts "\nRESULT: #{@failures.empty? ? 'PASS' : 'FAIL'}"
    exit(@failures.empty? ? 0 : 1)
  end
end

show = ARGV.include?('--show')
if show
  puts '*' * 72
  puts '--show prints raw matched values. Do NOT paste this output to an AI agent.'
  puts '*' * 72
end
Wcp.run_safely { Auditor.new(show:).run }
