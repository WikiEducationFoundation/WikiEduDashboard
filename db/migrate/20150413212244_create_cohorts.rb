class CreateCohorts < ActiveRecord::Migration[4.2]
  def self.up
    create_table :cohorts do |t|
      t.string :title
      t.string :slug
      t.string :url
      t.timestamps
    end

    create_table :cohorts_courses do |t|
      t.integer :cohort_id
      t.integer :course_id
      t.timestamps
    end

    execute %(
      INSERT INTO cohorts(title, slug, url, created_at, updated_at)
        SELECT DISTINCT
          REPLACE(CONCAT(UCASE(LEFT(cohort, 1)), SUBSTRING(cohort, 2)), '_', ' '),
          cohort,
          NULL,
          NOW(),
          NOW()
        FROM courses co
        WHERE cohort IS NOT NULL
    )
    Course.distinct.pluck(:cohort).each do |cohort|
      next if cohort.nil?
      url = ENV['cohort_' + cohort]
      execute %(
        UPDATE cohorts ch
        SET ch.url = '#{url}'
        WHERE ch.slug = '#{cohort}'
      )
    end

    execute %(
      INSERT INTO cohorts_courses(cohort_id, course_id, created_at, updated_at)
        SELECT ch.id, co.id, NOW(), NOW()
        FROM courses co
        LEFT JOIN `cohorts` ch
        ON ch.slug = co.cohort
        WHERE cohort IS NOT NULL
    )
    remove_column :courses, :cohort
  end

  def self.down
    add_column :courses, :cohort, :string
    execute %(
      UPDATE courses co
      LEFT JOIN cohorts ch ON EXISTS (
        SELECT * FROM cohorts_courses
        WHERE cohort_id = ch.id
        AND course_id = co.id
        ORDER BY id
        LIMIT 1
      )
      SET co.cohort = REPLACE(LCASE(ch.title), ' ', '_')
    )

    drop_table :cohorts
    drop_table :cohorts_courses
  end
end
