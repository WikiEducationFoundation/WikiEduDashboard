# frozen_string_literal: true

require 'rails_helper'

describe BuildGitPatch do
  def build(changed_files)
    described_class.new(base_files: { 'notes/a.txt' => "one\n", 'notes/b.txt' => "bee\n" },
                        changed_files:, message: 'Change notes',
                        author_name: 'Pat Admin', author_email: '').patch
  end

  it 'builds a format-patch email with full blob ids' do
    patch = build('notes/a.txt' => "two\n")
    expect(patch).to include("From: Pat Admin <>\n", 'Subject: [PATCH] Change notes')
    expect(patch).to match(/^index \h{40}\.\.\h{40} 100644$/)
    expect(patch).to include("-one\n+two\n")
  end

  it 'adds and deletes files' do
    patch = build('notes/c.txt' => "sea\n", 'notes/b.txt' => nil)
    expect(patch).to include('new file mode 100644', 'deleted file mode 100644')
  end

  it 'refuses paths outside the repository' do
    expect { build('../escape.txt' => 'x') }.to raise_error(ArgumentError)
    expect { build('/tmp/escape.txt' => 'x') }.to raise_error(ArgumentError)
  end
end
