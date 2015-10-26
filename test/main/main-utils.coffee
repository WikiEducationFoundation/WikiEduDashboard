require '../specHelper'
require '../../app/assets/javascripts/main-utils'

describe 'main-utils', ->
  describe 'String.trunc', ->
    it 'shorterns a string to 15 characters plus elipsis', ->
      testString = 'abcdefghijklmnopqrstuvwxyz'
      truncatedString = testString.trunc()
      truncatedString.should.equal 'abcdefghijklmno...'
