base_path = if ENV['training_path']
              "#{Rails.root}/#{ENV['training_path']}"
            else
              "#{Rails.root}/training_content/wiki_ed"
            end
TrainingLibrary.load(base_path: base_path)
TrainingModule.load(base_path: base_path)
TrainingSlide.load(base_path: base_path)
