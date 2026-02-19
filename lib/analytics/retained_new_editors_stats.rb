class RetainedNewEditorsStats
  MINIMUM_EDITS = 1   # could be configurable
  DAYS_AFTER_END = 7

  def initialize(course)
    @course = course
  end

  def count
    return 0 if @course.end.nil? || new_editors.empty?

    threshold = (@course.end + DAYS_AFTER_END.days)

    retained = 0

    # Current implementation is limited to home_wiki
    # does not aggregate across all course wikis

    wiki = @course.home_wiki || @course.wikis.first

    new_editors.pluck(:username).in_groups_of(40, false) do |batch|
      next if batch.empty?
      retained += count_retained_in_batch(batch, threshold, wiki)
    end

    retained
  end

  private

  def new_editors
    @new_editors ||= @course.students.where(registered_at: @course.start..@course.end)
  end

  def count_retained_in_batch(usernames, threshold, wiki)

    query = {
      list: 'usercontribs',
      ucuser: usernames,
      ucnamespace: 0,  # mainspace only
      ucstart: threshold.strftime('%Y%m%d%H%M%S'),
      uclimit: 500,      # Account for all distinct contributions by users
      ucprop: '', 
      ucdir: 'newer'
    }

    response = WikiApi.new(wiki).query(query)
    contribs = response&.data&.dig('usercontribs') || []
    
    # Count distinct users who have at least 1 contrib after threshold
    contribs.map { |c| c['user'] }.uniq.size
  end
end