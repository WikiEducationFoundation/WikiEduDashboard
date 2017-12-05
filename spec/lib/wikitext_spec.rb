# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/wikitext"

describe Wikitext do
  let(:subject) { described_class }

  describe '.markdown_to_mediawiki' do
    it 'should return a wikitext formatted version of the markdown input' do
      title = subject.markdown_to_mediawiki('# Title #')
      text = subject.markdown_to_mediawiki('This is some plain text')
      response = title + text
      expect(response).to eq("= Title =\n\nThis is some plain text\n\n")
    end
  end

  describe '.replace_code_with_nowiki' do
    it 'should convert code formatting syntax from html to wikitext' do
      code_snippet = '<code></code>'
      response = subject.replace_code_with_nowiki(code_snippet)
      expect(response).to eq('<nowiki></nowiki>')
    end

    it 'should not return nil if there are no code snippet' do
      code_snippet = 'no code snippet here'
      response = subject.replace_code_with_nowiki(code_snippet)
      expect(response).to eq('no code snippet here')
    end
  end

  describe '.replace_at_sign_with_template' do
    it 'should reformat email addresses' do
      code_snippet = 'My email is email@example.com.'
      response = subject.replace_at_sign_with_template(code_snippet)
      expect(response).to eq('My email is email{{@}}example.com.')
    end
  end

  describe '.substitute_bad_links' do
    it 'should find links and munge them into readable non-urls' do
      code_snippet = 'My bad links are bit.ly/foo and http://ur1.ca/bar'
      bad_links = ['bit.ly/foo', 'ur1.ca/bar']
      response = subject.substitute_bad_links(code_snippet, bad_links)
      expect(response).to include 'bit(.)ly/foo'
      expect(response).to include 'ur1(.)ca/bar'
      expect(response).not_to include 'bit.ly/foo'
      expect(response).not_to include 'ur1.ca/bar'
    end
  end

  describe '.titles_to_wikilinks' do
    it 'converts an array of titles into wikilink format' do
      titles = ['Selfie', 'Category:Photography', 'Bishnu_Priya']
      output = subject.titles_to_wikilinks(titles)
      expect(output).to include('[[Selfie]],')
      expect(output).to include('[[:Category:Photography]]')
      expect(output).to include('[[Bishnu Priya]]')
    end
  end
end
