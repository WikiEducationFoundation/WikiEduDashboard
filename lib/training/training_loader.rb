# frozen_string_literal: true

class TrainingLoader
  def initialize(content_class:, cache_key:, path_to_yaml:, trim_id_from_filename:)
    @collection = []
    @content_class = content_class

    @cache_key = cache_key
    @path_to_yaml = path_to_yaml
    @wiki_root_page = 'User:Ragesoss/data.json'
    @trim_id_from_filename = trim_id_from_filename
  end

  def load
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

  def wiki_source_pages
    [@wiki_root_page]
  end

  def new_from_wiki_page(wiki_page)
    wikitext = WikiApi.new(MetaWiki.new).get_page_content(wiki_page)
    content = JSON.parse(wikitext).to_hashugar
    @content_class.new(content, content.slug)
  end

  def new_from_file(yaml_file)
    slug = File.basename(yaml_file, '.yml')
    slug.gsub!(/^[0-9]+-/, '') if @trim_id_from_filename

    content = YAML.load_file(yaml_file).to_hashugar
    @content_class.new(content, slug)
  end
end
