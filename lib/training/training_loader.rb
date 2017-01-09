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

  def new_from_wiki_page(wiki_page)
    wikitext = WikiApi.new(MetaWiki.new).get_page_content(wiki_page)
    content = JSON.parse(wikitext)
    if content['wiki_page']
      base_text = WikiApi.new(MetaWiki.new).get_page_content(content['wiki_page'])
      content['title'] = title_from_translatable_wikitext(base_text)
      content['content'] = content_from_translatable_wikitext(base_text)
      content['translations'] = {}
      translated_wiki_pages(base_page: content['wiki_page']).each do |translated_page|
        translated_text = WikiApi.new(MetaWiki.new).get_page_content(translated_page)
        language = translated_page.split('/').last
        pp translated_text if language == 'es'
        translated_title = title_from_translated_wikitext(translated_text)
        translated_content = content_from_translated_wikitext(translated_text)
        content['translations'][language] = { 'title' => translated_title,
                                              'content' => translated_content }
      end
    end
    content = content.to_hashugar
    @content_class.new(content, content.slug)
  end

  def title_from_translatable_wikitext(wikitext)
    clean_text = wikitext.split(%r{(</translate>)})[0].gsub(/.*<translate>/m, '').force_encoding("UTF-8")
    clean_text = clean_text.gsub(/<!--.+?-->/, '') # remove translation marker comments
    clean_text
  end

  def content_from_translatable_wikitext(wikitext)
    clean_text = wikitext.split(%r{(</translate>)})[2..-1]&.join&.force_encoding("UTF-8")
    converter = PandocRuby.new(clean_text, from: :mediawiki, to: :markdown)
    converter.convert
  end

  def title_from_translated_wikitext(wikitext)
    clean_text = wikitext.gsub(%r{(<noinclude>.*?</noinclude>\n*)}, '').force_encoding("UTF-8")
    clean_text.lines.first.chomp

  end

  def content_from_translated_wikitext(wikitext)
    clean_text = wikitext.gsub(%r{(<noinclude>.*?</noinclude>\n*)}, '').force_encoding("UTF-8")
    clean_text = clean_text.lines[1..-1].join
    converter = PandocRuby.new(clean_text, from: :mediawiki, to: :markdown)
    converter.convert
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

  def translated_wiki_pages(base_page:)
    return [] unless base_page
    translations_query = { meta: 'messagegroupstats',
                           mgsgroup: "page-#{base_page}" }
    response = WikiApi.new(MetaWiki.new).query(translations_query)
    return [] unless response
    translations = []
    response.data['messagegroupstats'].each do |language|
      next if language['total'].zero?
      next unless language['total'] == language['translated']
      translations << base_page + '/' + language['code']
    end
    pp translations
    return translations
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
