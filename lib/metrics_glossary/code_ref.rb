# frozen_string_literal: true

class MetricsGlossary
  #= A pointer from a glossary entry to code: a Ruby method or constant, a JS
  # definition, or a whole file. Pointers name symbols rather than line
  # numbers, so they survive edits; the line is looked up when the page
  # renders.
  #
  #   ruby: WordCount.from_characters      # class method
  #   ruby: Course#word_count              # instance method
  #   ruby: WordCount::EXCLUDED_PROJECTS   # constant
  #   path: lib/word_count.rb              # required for lib/ code, which isn't autoloaded
  #   formula: true                        # fingerprint the method's source
  #
  # Constants are always fingerprinted, by value, since a changed value (like
  # the bytes-per-word ratio) changes every metric that uses it.
  #
  #   js: app/assets/javascripts/utils/wordcount_utils.js#bytesToWords
  #   file: app/views/term_recap_mailer/email.html.haml
  class CodeRef
    KINDS = %w[ruby js file].freeze
    KEYS = (KINDS + %w[path formula note]).freeze
    RUBY_METHOD = /\A(?<owner>[A-Z][\w:]*)(?<sep>[#.])(?<name>\w+[?!=]?)\z/

    attr_reader :kind, :target, :note, :raw

    def self.from_hash(hash)
      hash ||= {}
      kind = KINDS.find { |candidate| hash.key?(candidate) }
      new(kind:, target: hash[kind], declared_path: hash['path'],
          formula: hash['formula'], note: hash['note'], raw: hash)
    end

    def initialize(kind:, target:, declared_path: nil, formula: nil, note: nil, raw: {})
      @kind = kind
      @target = target.to_s
      @declared_path = declared_path
      @formula = formula
      @note = note
      @raw = raw
    end

    def formula?
      @formula == true
    end

    def ruby_method?
      kind == 'ruby' && RUBY_METHOD.match?(target)
    end

    def label
      kind == 'js' ? target.split('#').last : target
    end

    def path
      location[:path]
    end

    def line
      location[:line]
    end

    def url(revision = MetricsGlossary.revision)
      anchor = line ? "#L#{line}" : ''
      "#{MetricsGlossary::REPO_URL}/blob/#{revision}/#{path}#{anchor}"
    end

    # Nil when the pointer resolves, otherwise a description of what's wrong.
    def error
      return "#{raw.inspect}: needs exactly one of #{KINDS.join(', ')}" if kind.nil?
      return "#{target}: formula: true only applies to Ruby methods" if formula? && !ruby_method?
      location
      nil
    rescue StandardError, LoadError => e
      "#{target}: #{e.message}"
    end

    # Formula methods are fingerprinted by source, and constants by value.
    # Classes and modules aren't: their value is just their name.
    def fingerprinted?
      return formula? if ruby_method?
      kind == 'ruby' && !constant_value.is_a?(Module)
    end

    # What the fingerprint is taken of: a method's source, or a constant's value.
    def fingerprint_source
      ruby_method? ? ruby_method.source : "#{target} = #{constant_value.inspect}"
    end

    private

    def location
      @location ||= case kind
                    when 'ruby' then ruby_location
                    when 'js' then js_location
                    else file_location
                    end
    end

    def ruby_location
      require_dependency Rails.root.join(@declared_path).to_s if @declared_path&.start_with?('lib/')
      file, line = ruby_method? ? ruby_method.source_location : constant_location
      path = Pathname.new(file).relative_path_from(Rails.root).to_s
      if @declared_path && path != @declared_path
        raise ArgumentError, "is defined in #{path}, not #{@declared_path}"
      end
      { path:, line: }
    end

    def ruby_method
      @ruby_method ||= begin
        match = RUBY_METHOD.match(target)
        owner = match[:owner].constantize
        match[:sep] == '#' ? owner.instance_method(match[:name]) : owner.method(match[:name])
      end
    end

    def constant_value
      location # loads lib/ files first
      target.constantize
    end

    def constant_location
      target.constantize
      Object.const_source_location(target).presence || raise(NameError, 'has no source location')
    end

    def js_location
      path, name = target.split('#', 2)
      lines = File.readlines(Rails.root.join(path))
      return { path:, line: nil } unless name

      index = lines.index { |source_line| js_definition(name).match?(source_line) }
      raise ArgumentError, "no definition of #{name} in #{path}" unless index
      { path:, line: index + 1 }
    end

    # Matches the usual ways a function, constant or component is defined:
    # `function name`, `const name =`, `class name`, `name(...) {` or `name: ...`.
    def js_definition(name)
      name = Regexp.escape(name)
      Regexp.union(/\b(?:function|class|const|let|var)\s+#{name}\b/,
                   /^\s*(?:static\s+|async\s+)*#{name}\s*(?:=|\()/,
                   /\b#{name}\s*:\s*(?:\(|function|async)/)
    end

    def file_location
      raise ArgumentError, 'file does not exist' unless File.exist?(Rails.root.join(target))
      { path: target, line: nil }
    end
  end
end
