require '../testHelper'
require '../../app/assets/javascripts/main-utils'

describe 'main-utils', ->
  describe 'String.trunc', ->
    it 'shorterns a string to 15 characters plus ellipsis', ->
      testString = 'áBcdèfghijklmnopqrstuvwxyz'
      truncatedString = testString.trunc()
      truncatedString.should.equal 'áBcdèfghijklmno...'

  describe 'String.capitalize', ->
    it 'upcases the first letter of a string', ->
      testString = 'abCDE fg'
      truncatedString = testString.capitalize()
      truncatedString.should.equal 'AbCDE fg'
    it 'handles unicode properly', ->
      testString = 'ábCDEfg'
      truncatedString = testString.capitalize()
      truncatedString.should.equal 'ÁbCDEfg'
