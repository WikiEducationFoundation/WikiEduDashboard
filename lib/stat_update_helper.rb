# frozen_string_literal: true

module StatUpdateHelper
  # Arel condition: users who registered during (or shortly before) a course.
  def self.new_editor_date_condition(prereg: false)
    users_table = User.arel_table
    courses_table = Course.arel_table

    start_bound = if prereg
                    Arel::Nodes::NamedFunction.new(
                      'DATE_SUB', [courses_table[:start], Arel.sql('INTERVAL 60 DAY')]
                    )
                  else
                    courses_table[:start]
                  end

    users_table[:registered_at].gteq(start_bound)
                               .and(users_table[:registered_at].lteq(courses_table[:end]))
  end
end
