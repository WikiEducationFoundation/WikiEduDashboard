# frozen_string_literal: true

class TrainingLoader
  def initialize(content_class:, cache_key:, path_to_yaml:, trim_id_from_filename:, wiki_base_page:)
    @collection = []
    @content_class = content_class

    @cache_key = cache_key
    @path_to_yaml = path_to_yaml
    @wiki_base_page = wiki_base_page
    @trim_id_from_filename = trim_id_from_filename
  end

  def load
    load_from_yaml
    write_to_cache
  end

  def load_all
    load_from_yaml
    load_from_wiki
    write_to_cache
  end

  private

  def load_from_yaml
    Dir.glob(@path_to_yaml) do |yaml_file|
      @collection << new_from_file(yaml_file)
    end
  end

  def load_from_wiki
    wiki_source_pages.each do |wiki_page|
      content = new_from_wiki_page(wiki_page)
      next unless content.valid?
      @collection << new_from_wiki_page(wiki_page)
    end
  end

  def write_to_cache
    Rails.cache.write @cache_key, @collection
  end

  def wiki_source_pages(base_page: nil)
    link_source = base_page || @wiki_base_page
    query_params = { prop: 'links', titles: link_source }
    response = WikiApi.new(MetaWiki.new).query(query_params)
    begin
      response.data['pages'].values[0]['links'].map { |page| page['title'] }
    rescue
      []
    end
  end

  def new_from_wiki_page(wiki_page)
    wikitext = WikiApi.new(MetaWiki.new).get_page_content(wiki_page)
    content = JSON.parse(wikitext)
    if content['wiki_page']
      base_text = WikiApi.new(MetaWiki.new).get_page_content(content['wiki_page'])
      base_title = base_text.lines.first.chomp
      base_content = base_text.lines[1..-1].join
      content['title'] = extract_text_from_translate_tags(base_title)
      content['content'] = base_content
      content['translations'] = {}
      wiki_source_pages(base_page: content['wiki_page']).each do |translated_page|
        translated_text = WikiApi.new(MetaWiki.new).get_page_content(translated_page)
        language = translated_page.split('/').last
        translated_title = extract_text_from_translate_tags(translated_text.lines.first.chomp)
        translated_content = translated_text.lines[1..-1].join
        content['translations'][language] = { 'title' => translated_title,
                                              'content' => translated_content }
      end
    end
    content = content.to_hashugar
    @content_class.new(content, content.slug)
  end

  # rubocop: disable Style/RegexpLiteral
  def extract_text_from_translate_tags(wikitext)
    wikitext.gsub(%r{.*<translate>}, '').gsub(%r{</translate>.*}, '')
  end
  # rubocop: enable Style/RegexpLiteral

  def new_from_file(yaml_file)
    slug = File.basename(yaml_file, '.yml')
    slug.gsub!(/^[0-9]+-/, '') if @trim_id_from_filename

    content = YAML.load_file(yaml_file).to_hashugar
    @content_class.new(content, slug)
  end
end
