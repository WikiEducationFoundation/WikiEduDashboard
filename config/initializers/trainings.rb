begin
  TrainingModule.load_all
rescue TrainingBase::DuplicateIdError, TrainingBase::DuplicateSlugError => e
  puts e.message
end
