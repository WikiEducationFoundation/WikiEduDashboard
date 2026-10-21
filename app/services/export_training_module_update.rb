# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/training/training_content_files"
require_dependency "#{Rails.root}/lib/training/training_yaml_editor"

# Works out the file changes that turn an update draft's source module (see
# CopyTrainingModuleToDraft) into the draft, and exports them as a git patch.
#
# Only the values the composer edits are rewritten; other fields (quizzes,
# translations, settings) and the formatting of untouched values stay as they
# are. New slides get the next free ids in the module's range and go in the
# module's slide directory. A slide that another module also lists keeps its
# slug, and its file isn't deleted when it's removed from this module.
class ExportTrainingModuleUpdate
  # Paths mapped to their new text, or to nil for deletion.
  attr_reader :changed_files

  SLIDE_LIST_ITEM = /\A(\s*)-\s+slug:\s*['"]?([\w-]+)['"]?/

  def initialize(draft, content_files: TrainingContentFiles.new)
    @draft = draft
    @source = draft.source
    @content_files = content_files
    @new_slide_ids = assign_new_slide_ids
    @changed_files = build_changed_files
  end

  def filename
    "#{@source.module_slug}-update-#{Time.current.strftime('%Y%m%d')}.patch"
  end

  def patch(author_name:, author_email:)
    BuildGitPatch.new(base_files: @source.files, changed_files:,
                      message: "Update #{@source.module_slug} training module",
                      author_name:, author_email:).patch
  end

  # [{ 'path', 'status' }] where status is 'added', 'modified', or 'deleted'.
  def change_list
    changed_files.map do |path, text|
      status = if text.nil? then 'deleted'
               elsif @source.files.key?(path) then 'modified'
               else 'added'
               end
      { 'path' => path, 'status' => status }
    end
  end

  private

  def build_changed_files
    files = { @source.module_path => module_text }
    @draft.slides.each_with_index do |slide, index|
      original = original_for(slide)
      original ? copied_slide_files(slide, original, files) : new_slide_file(slide, index, files)
    end
    removed_slide_paths.each { |path| files[path] = nil }
    files.reject { |path, text| @source.files[path] == text }
  end

  def module_text
    editor = TrainingYamlEditor.new(@source.files[@source.module_path])
    %w[name description estimated_ttc].each do |key|
      set_if_changed(editor, key, @draft.public_send(key))
    end
    slugs = @draft.slides.map { |slide| export_slug(slide) }
    unless slugs == (editor.data['slides'] || []).pluck('slug')
      editor.set('slides', slugs.map { |slug| { 'slug' => slug } },
                 text: slide_list_text(editor.original_text('slides')))
    end
    editor.to_s
  end

  def copied_slide_files(slide, original, files)
    editor = TrainingYamlEditor.new(@source.files[original['path']])
    set_if_changed(editor, 'title', slide['title'])
    set_if_changed(editor, 'content', slide['content'])
    directory, filename = File.split(original['path'])
    path = File.join(directory, "#{filename[/\A\d+-/]}#{export_slug(slide)}.yml")
    files[original['path']] = nil if path != original['path']
    files[path] = editor.to_s
  end

  def new_slide_file(slide, index, files)
    id = @new_slide_ids[index]
    editor = TrainingYamlEditor.new('')
    editor.set('title', slide['title'])
    editor.set('id', id)
    editor.set('content', normalize(slide['content'], nil))
    filename = "#{format('%04d', id)}-#{slide['slug']}.yml"
    files[File.join(new_slide_directory, filename)] = editor.to_s
  end

  def removed_slide_paths
    kept = @draft.slides.filter_map { |slide| original_for(slide)&.fetch('id') }
    @source.slides.filter_map do |original|
      original['path'] unless kept.include?(original['id']) || shared?(original['slug'])
    end
  end

  def original_for(slide)
    slide['id'] && @source.slide(slide['id'])
  end

  # The composer doesn't offer renaming a shared slide, since the other
  # modules that list it would lose it.
  def export_slug(slide)
    original = original_for(slide)
    original && shared?(original['slug']) ? original['slug'] : slide['slug']
  end

  def shared?(slide_slug)
    (@content_files.modules_using_slide(slide_slug) - [@source.module_slug]).any?
  end

  # Only rewrites a value whose text really changed; trailing whitespace alone
  # doesn't count.
  def set_if_changed(editor, key, value)
    original = editor.data[key]
    return if original.to_s.rstrip == value.to_s.rstrip
    editor.set(key, normalize(value, original))
  end

  # Multi-line text ends with exactly one newline: a plain `|` block.
  def normalize(value, original)
    value = value.to_s
    return value unless value.include?("\n") || original.to_s.end_with?("\n")
    "#{value.rstrip}\n"
  end

  # Keeps each listed slide's original line (and any `# id` comment on it), and
  # writes new lines in the same style.
  def slide_list_text(original)
    lines = (original || '').lines
    items = lines.drop(1).grep(SLIDE_LIST_ITEM).index_by { |line| line[SLIDE_LIST_ITEM, 2] }
    template = items.values.first
    header = lines.first&.start_with?('slides:') ? lines.first : "slides:\n"
    header + @draft.slides.each_with_index.map do |slide, index|
      slide_list_line(slide, items, template, @new_slide_ids[index] || slide['id'])
    end.join
  end

  def slide_list_line(slide, items, template, id)
    slug = export_slug(slide)
    original_slug = original_for(slide)&.fetch('slug')
    line = items[original_slug]
    return line.sub(/slug:\s*\S+/, "slug: #{slug}") if line && slug != original_slug
    return line if line
    indent = template ? template[SLIDE_LIST_ITEM, 1] : '  '
    comment = template&.match(/#(\s*)\d+\s*\z/) ? " ##{Regexp.last_match(1)}#{id}" : ''
    "#{indent}- slug: #{slug}#{comment}\n"
  end

  def new_slide_directory
    own_slide = @source.slides.find { |slide| slide['id'] / 100 == @draft.module_id }
    return File.dirname(own_slide['path']) if own_slide
    slides_root = TrainingContentFiles.relative_path(File.join(TrainingBase.base_path, 'slides'))
    File.join(slides_root, "#{@draft.module_id}-#{@source.module_slug}")
  end

  # Slide ids are module_id * 100 + n by convention, so new slides continue
  # from the highest id already used in the module's range.
  def assign_new_slide_ids
    taken = Set.new(TrainingSlide.pluck(:id) + @content_files.slide_ids + @source.slide_ids)
    range_start = @draft.module_id * 100
    candidate = taken.select { |id| id / 100 == @draft.module_id }.max || range_start
    @draft.slides.each_with_index.with_object({}) do |(slide, index), ids|
      next if original_for(slide)
      candidate += 1
      candidate += 1 while taken.include?(candidate)
      ids[index] = candidate
    end
  end
end
