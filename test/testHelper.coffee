#----------------------------------------
# Global Requirements

global.jsdom = require 'mocha-jsdom'
global.testdom = require('testdom')('<html><body></body></html>')
global.sinon = require 'sinon'
global.React = require 'react'
global.ReactDOM = require 'react-dom'
global.ReactTestUtils = require 'react-addons-test-utils'
global.Simulate = ReactTestUtils.Simulate
global.$ = require 'jquery'
global._ = require 'lodash'
global.moment = require 'moment'
global.moment-recur = require 'moment-recur'
global.I18n = require 'i18n-js'
global.chai = require 'chai'

require 'jsx-require-extension'
require '../app/assets/javascripts/main-utils'

#----------------------------------------
# Global Config

jsdom
  skipWindowCheck: true

global.expect = chai.expect
global.assert = chai.assert
