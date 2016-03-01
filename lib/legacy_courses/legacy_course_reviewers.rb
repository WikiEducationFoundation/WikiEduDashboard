#= Routines for parsing legacy course reviewers data and getting it ready to generate Assignments
class LegacyCourseReviewers
  def self.find_reviewers(group)
    new(group).reviewers
  end

  def initialize(group)
    @group = group
    @reviewers = []
  end

  def reviewers
    @group.each do |user|
      reviewers_for_one_user(user)
    end
    @reviewers
  end

  def reviewers_for_one_user(user)
    # Add reviewers
    a_index = r_index = 0
    while user.key? a_index.to_s
      while user[a_index.to_s].key? r_index.to_s
        add_reviewer(user, a_index, r_index)
        r_index += 1
      end
      a_index += 1
    end
  end

  def add_reviewer(user, a_index, r_index)
    @reviewers.push(
      'username' => user[a_index.to_s][r_index.to_s]['username'],
    )
  end
end
