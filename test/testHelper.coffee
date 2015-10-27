#----------------------------------------
# Global Requirements

global.jsdom = require 'mocha-jsdom'
global.testdom = require('testdom')('<html><body></body></html>')
global.React = require 'react/addons'
global.ReactTestUtils = React.addons.TestUtils
global.Simulate = ReactTestUtils.Simulate
global.$ = require 'jquery'
global._ = require 'lodash'
global.I18n = require 'i18n-js'
global.chai = require 'chai'

require 'jsx-require-extension'

#----------------------------------------
# Global Config

jsdom
  skipWindowCheck: true

chai.should()
global.expect = chai.expect
global.assert = chai.assert
