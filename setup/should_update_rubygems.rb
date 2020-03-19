current_rubygems_version = Gem::Version.new(`gem -v`.chomp)
rubygems_version_after_bugfix = Gem::Version.new('2.7.10')

if current_rubygems_version < rubygems_version_after_bugfix
  exit 0 # success -- should update rubygems
else
  exit 1 # fail -- already updated, no update needed
end
