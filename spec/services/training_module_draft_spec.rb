# frozen_string_literal: true

require 'rails_helper'

describe TrainingModuleDraft do
  let(:tmp_dir) { Rails.root.join('tmp', 'training_module_draft_spec') }

  before do
    FileUtils.rm_rf(tmp_dir)
    FileUtils.mkdir_p(tmp_dir)
    stub_const('TrainingModuleDraft::DIRNAME', tmp_dir.relative_path_from(Rails.root).to_s)
  end

  after { FileUtils.rm_rf(tmp_dir) }

  describe 'slug validation' do
    it 'accepts valid slugs' do
      expect { described_class.validate_slug!('my-module-1') }.not_to raise_error
    end

    it 'rejects path-traversal attempts' do
      expect { described_class.validate_slug!('../etc/passwd') }
        .to raise_error(TrainingModuleDraft::InvalidSlug)
    end

    it 'rejects uppercase and whitespace' do
      expect { described_class.validate_slug!('My Module') }
        .to raise_error(TrainingModuleDraft::InvalidSlug)
    end

    it 'rejects empty strings' do
      expect { described_class.validate_slug!('') }
        .to raise_error(TrainingModuleDraft::InvalidSlug)
    end
  end

  describe '.all' do
    it 'returns [] when the directory does not exist' do
      FileUtils.rm_rf(tmp_dir)
      expect(described_class.all).to eq([])
    end

    it 'returns drafts in most-recently-updated order' do
      first = described_class.new(slug: 'first', name: 'First')
      first.save
      # Ensure distinct mtimes on systems with coarse mtime resolution
      sleep 1.1
      second = described_class.new(slug: 'second', name: 'Second')
      second.save

      expect(described_class.all.map(&:slug)).to eq(%w[second first])
    end
  end

  describe '.find' do
    it 'loads a draft by slug' do
      described_class.new(slug: 'alpha', name: 'Alpha',
                          slides: [{ 'slug' => 's1', 'title' => 'T', 'content' => 'C' }]).save
      draft = described_class.find('alpha')
      expect(draft.name).to eq('Alpha')
      expect(draft.slides.length).to eq(1)
    end

    it 'raises NotFound for a missing draft' do
      expect { described_class.find('nope') }.to raise_error(TrainingModuleDraft::NotFound)
    end
  end

  describe '#save' do
    it 'allocates a fresh module_id on first save' do
      allow(TrainingModule).to receive(:pluck).with(:id).and_return([1, 2, 74])
      draft = described_class.new(slug: 'fresh', name: 'Fresh').save
      expect(draft.module_id).to eq(75)
    end

    it 'keeps an existing module_id across saves when it stays unique' do
      allow(TrainingModule).to receive(:pluck).with(:id).and_return([1, 2, 74])
      draft = described_class.new(slug: 'stable', name: 'Stable').save
      original_id = draft.module_id
      draft.name = 'Renamed'
      draft.save
      expect(draft.module_id).to eq(original_id)
    end

    it 'avoids colliding with another draft' do
      allow(TrainingModule).to receive(:pluck).with(:id).and_return([])
      described_class.new(slug: 'a', name: 'A').save
      draft_b = described_class.new(slug: 'b', name: 'B').save
      expect(draft_b.module_id).to eq(2)
    end
  end

  describe '#slide_id_for' do
    it 'composes ids as module_id * 100 + 1-indexed position' do
      draft = described_class.new(slug: 'x', name: 'X', module_id: 75)
      expect(draft.slide_id_for(0)).to eq(7501)
      expect(draft.slide_id_for(3)).to eq(7504)
    end
  end

  describe '#destroy' do
    it 'removes the draft file' do
      draft = described_class.new(slug: 'gone', name: 'Gone').save
      expect(draft.path).to exist
      draft.destroy
      expect(draft.path).not_to exist
    end
  end

  describe '#rename!' do
    it 'moves the draft file to the new slug and preserves content' do
      draft = described_class.new(slug: 'old', name: 'Old',
                                  slides: [{ 'slug' => 's1', 'title' => 'T',
                                             'content' => 'Body' }]).save
      old_path = draft.path
      draft.rename!('renamed')
      expect(old_path).not_to exist
      expect(draft.path).to exist
      reloaded = described_class.find('renamed')
      expect(reloaded.name).to eq('Old')
      expect(reloaded.slides.first['title']).to eq('T')
    end

    it 'raises SlugTaken when the new slug is already in use' do
      described_class.new(slug: 'existing', name: 'E').save
      draft = described_class.new(slug: 'source', name: 'S').save
      expect { draft.rename!('existing') }
        .to raise_error(TrainingModuleDraft::SlugTaken)
    end

    it 'raises InvalidSlug for malformed new slugs' do
      draft = described_class.new(slug: 'ok', name: 'O').save
      expect { draft.rename!('Bad Slug') }
        .to raise_error(TrainingModuleDraft::InvalidSlug)
    end

    it 'is a no-op when the slug is unchanged' do
      draft = described_class.new(slug: 'stay', name: 'Stay').save
      expect { draft.rename!('stay') }.not_to change { described_class.all.length }
    end
  end

  describe 'slide normalization' do
    it 'coerces missing fields to empty strings' do
      draft = described_class.new(slug: 'n', name: 'N', slides: [{ 'title' => 'Only title' }])
      expect(draft.slides.first).to eq('slug' => '', 'title' => 'Only title', 'content' => '')
    end

    it 'rejects slide slugs that would escape the slide directory at export time' do
      expect do
        described_class.new(slug: 'n', name: 'N',
                            slides: [{ 'slug' => '../../etc/passwd', 'title' => 'X',
                                       'content' => '' }])
      end.to raise_error(TrainingModuleDraft::InvalidSlug)
    end

    it 'rejects slide slugs with whitespace or capitals' do
      expect do
        described_class.new(slug: 'n', name: 'N',
                            slides: [{ 'slug' => 'Bad Slug', 'title' => 'X',
                                       'content' => '' }])
      end.to raise_error(TrainingModuleDraft::InvalidSlug)
    end
  end

  describe 'reserved slugs' do
    it 'rejects Rails conventional slugs like new, edit, index' do
      %w[new edit index].each do |reserved|
        expect { described_class.validate_slug!(reserved) }
          .to raise_error(TrainingModuleDraft::InvalidSlug, /reserved/)
      end
    end
  end

  describe '.all with malformed drafts' do
    it 'skips unreadable files rather than raising' do
      described_class.new(slug: 'ok', name: 'Good').save
      bad = tmp_dir.join('bad.yml')
      bad.write('not: valid: yaml: [[[')
      expect(described_class.all.map(&:slug)).to eq(['ok'])
    end
  end
end
