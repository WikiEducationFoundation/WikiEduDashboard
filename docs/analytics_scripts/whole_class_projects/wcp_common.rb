# frozen_string_literal: true

# Shared helpers for the whole-class projects research scripts. See PLAN.md.
#
# Everything here is written to keep private data out of script output: nothing
# in this file prints a database value, and safe_error_message strips quoted
# strings (where MySQL puts row values) from error messages.

require 'mysql2'
require 'set'

module Wcp
  RAW_DB = ENV.fetch('WCP_RAW_DB', 'wcp_raw')
  SANITIZED_DB = ENV.fetch('WCP_SANITIZED_DB', 'wcp_sanitized')
  DICTIONARY_PATH = '/usr/share/dict/words'

  # courses_users.role values (CoursesUsers::Roles)
  ROLE_TOKENS = {
    0 => 'STUDENT',
    1 => 'INSTRUCTOR',
    2 => 'VOLUNTEER',
    3 => 'VOLUNTEER',
    4 => 'STAFF'
  }.freeze
  # users.permissions values that mark Wiki Education staff
  STAFF_PERMISSIONS = [1, 3].freeze

  EMAIL_RE = /[[:alnum:]._%+-]+@[[:alnum:].-]+\.[[:alpha:]]{2,}/
  PHONE_RE = /(?<![\d-])(?:\+?1[\s.-]?)?\(?\d{3}\)?[\s.-]\d{3}[\s.-]\d{4}(?![\d-])/

  module_function

  def client(database = nil)
    Mysql2::Client.new(
      host: ENV.fetch('WCP_DB_HOST', '127.0.0.1'),
      port: Integer(ENV.fetch('WCP_DB_PORT', '3306')),
      username: ENV.fetch('WCP_DB_USER', 'wcp_sanitizer'),
      password: ENV.fetch('WCP_DB_PASSWORD'),
      database:,
      encoding: 'utf8mb4'
    )
  end

  # Canonical Wikipedia username form: underscores as spaces, first letter
  # uppercase.
  def normalize_username(username)
    name = username.to_s.tr('_', ' ').strip.squeeze(' ')
    name.empty? ? name : name[0].upcase + name[1..]
  end

  # Lowercase-only dictionary entries. Capitalized entries in the word list are
  # mostly proper names, which should not count as ordinary words.
  def dictionary
    @dictionary ||= if File.exist?(DICTIONARY_PATH)
                      File.foreach(DICTIONARY_PATH).map(&:chomp)
                          .grep(/\A[[:lower:]]+\z/).to_set
                    else
                      warn "No #{DICTIONARY_PATH}; treating no needles as dictionary words."
                      Set.new
                    end
  end

  def tokens(text)
    text.to_s.downcase.scan(/[[:alnum:]]+/)
  end

  def dictionary_word?(value)
    toks = tokens(value)
    toks.length == 1 && dictionary.include?(toks.first)
  end

  def safe_error_message(error)
    message = error.message.gsub(/'[^']*'/, "'…'").gsub(/"[^"]*"/, '"…"')
    "#{error.class}: #{message[0, 300]}"
  end

  def run_safely
    yield
  rescue StandardError => e
    abort "Failed (values redacted): #{safe_error_message(e)}"
  end
end
