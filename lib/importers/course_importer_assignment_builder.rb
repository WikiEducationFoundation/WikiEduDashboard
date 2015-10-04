class CourseImporterAssignmentBuilder
  def self.build_assignments_from_group_flat(course_id, group_flat)
    new(course_id, group_flat).build_assignments_from_group_flat
  end

  def initialize(course_id, group_flat)
    @course_id = course_id
    @group_flat = group_flat
    @assignments = []
  end

  def build_assignments_from_group_flat
    # Add assigned articles
    @group_flat.each do |user|
      # Each assigned article has a numerical (string) index, starting from 0.
      next unless user.key? '0'

      # Each user has username, id, & role. Extra keys are assigned articles.
      assignment_count = user.keys.count - 3

      (0...assignment_count).each do |a|
        raw = user[a.to_s]
        article = Article.find_by(title: raw['title'])
        # role 0 is for assignee
        assignment = assignment_hash(user, raw, article, 0)
        new_assignment = Assignment.new(assignment)
        @assignments.push new_assignment

        # Get the reviewers
        raw.each do |_key, reviewer|
          build_reviewer_assignments(reviewer, raw, article)
        end
      end
    end
    return @assignments
  end

  def build_reviewer_assignments(reviewer, raw, article)
    return unless reviewer.is_a?(Hash) && reviewer.key?('username')
    # role 1 is for reviewer
    assignment = assignment_hash(reviewer, raw, article, 1)

    new_assignment = Assignment.new(assignment)
    @assignments.push new_assignment
  end

  def assignment_hash(user, raw, article, role)
    {
      'user_id' => user['id'],
      'course_id' => @course_id,
      'article_title' => raw['title'],
      'article_id' => article.nil? ? nil : article.id,
      'role' => role
    }
  end
end
