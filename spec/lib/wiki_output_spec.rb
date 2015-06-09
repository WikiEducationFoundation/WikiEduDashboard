require 'rails_helper'
require "#{Rails.root}/lib/wiki_output"

describe WikiOutput do

  describe '.markdown_to_mediawiki' do
    it 'should return a wikitext formatted version of the markdown input' do
      title = WikiOutput.markdown_to_mediawiki("# Title #")
      text = WikiOutput.markdown_to_mediawiki("This is some plain text")
      response =  title + text
      expect(response).to eq("= Title =\n\nThis is some plain text\n\n")
    end
  end

  describe '.replace_code_with_nowiki' do
    it 'should convert code formatting syntax from html to wikitext' do
      code_snippet = "<code></code>"
      response = WikiOutput.replace_code_with_nowiki(code_snippet)
      expect(response).to eq("<nowiki></nowiki>")
    end

    it 'should not return nil if there are no code snippet' do
      code_snippet = "no code snippet here"
      response = WikiOutput.replace_code_with_nowiki(code_snippet)
      expect(response).to eq("no code snippet here")
    end
  end

  # describe '.translate_course' do 
  #   it 'should return a wikitext version of the course' do
  #     week1 = create(:week, id: 2, title: 'This is the beginning')
  #     week2 = create(:week, id: 3, title: 'This is the end')
  #     block1 = create(:block, id: 4, title: "Block 1 title", kind: 0, content: "block 1 content")
  #     block2 = create(:block, id: 5, title: "Block 2 title", kind: 1, content: "block 2 content")
  #     week1.blocks = [block1]
  #     week2.blocks = [block2]
  #     course = create(:course, id: 1, title: "# Title #", description: "The course description", weeks: [week1, week2])
  #     response = WikiOutput.translate_course(course)
  #     expect(response).to eq("The course description\n\n= Week 1 This is the beginning =\n\n{{start of course week}}\n\n== In Class ==\n\n=== Block 1 title ===\n\nblock 1 content\n\n{{end of course week}}\n\n= Week 2 This is the end =\n\n{{start of course week}}\n\n== Assignment ==\n\n=== Block 2 title ===\n\nblock 2 content\n\n{{end of course week}}\n\n")
  #   end
  # end

end