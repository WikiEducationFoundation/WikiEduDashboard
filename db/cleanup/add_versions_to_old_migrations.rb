# Run from db/migrate, like this:
# ruby "../cleanup/add_versions_to_old_migrations.rb"

Dir.glob('*').each do |migration|
  versioned_migration = File.read(migration).gsub("< ActiveRecord::Migration\n", "< ActiveRecord::Migration[4.2]\n")
  File.open(migration, 'w') do |output|
    output << versioned_migration
  end
end
