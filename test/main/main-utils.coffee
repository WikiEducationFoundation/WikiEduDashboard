require '../testHelper'
require '../../app/assets/javascripts/main-utils'

describe 'main-utils', ->
  describe 'String.trunc', ->
    it 'shorterns a string to 15 characters plus ellipsis', ->
      testString = 'áBcdèfghijklmnopqrstuvwxyz'
      truncatedString = testString.trunc()
      expect(truncatedString).to.eq 'áBcdèfghijklmno…'

  describe 'String.capitalize', ->
    it 'upcases the first letter of a string', ->
      testString = 'abCDE fg'
      truncatedString = testString.capitalize()
      expect(truncatedString).to.eq 'AbCDE fg'
    it 'handles unicode properly', ->
      testString = 'ábCDEfg'
      truncatedString = testString.capitalize()
      expect(truncatedString).to.eq 'ÁbCDEfg'
