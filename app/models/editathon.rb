class Editathon < Course
  def wiki_edits_enabled?
    false
  end

  def wiki_title
    nil
  end
end
