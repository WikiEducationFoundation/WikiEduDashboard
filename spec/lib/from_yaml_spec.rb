require 'rails_helper'
require "#{Rails.root}/lib/from_yaml"
require "#{Rails.root}/lib/training_module"

describe FromYaml do
  describe '.load' do
    let(:subject) do
      FromYaml.load(path_to_yaml: "#{Rails.root}/spec/support/bad_yaml_file.yml",
                    cache_key: 'test')
    end
    it 'outputs the filename when loading a misformatted file causes an error' do
      expect(STDOUT).to receive(:puts).with(/.*bad_yaml_file.*/)
      expect { subject }.to raise_error(NoMethodError)
    end
  end

  describe '.all' do
    it 'loads from yaml files if data is not in cache' do
      Rails.cache.clear
      expect(TrainingLibrary.all).not_to be_empty
      expect(TrainingModule.all).not_to be_empty
      expect(TrainingSlide.all).not_to be_empty
    end
  end
end
