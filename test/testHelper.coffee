#----------------------------------------
# Global Requirements

global.jsdom = require 'mocha-jsdom'
#global.testdom = require('testdom')('<html><body><div id="react_root" data-current_user="id: 1"></div></body></html>')
global.testdom = require('testdom')('<html><body><div></div></body></html>')
global.sinon = require 'sinon'
global.React = require 'react'
global.ReactDOM = require 'react-dom'
global.ReactTestUtils = require 'react-addons-test-utils'
global.Simulate = ReactTestUtils.Simulate
global.$ = require 'jquery'
global._ = require 'lodash'
global.moment = require 'moment'
global.moment-recur = require 'moment-recur'
global.I18n = require '../public/assets/javascripts/i18n.js'
global.chai = require 'chai'

require '../app/assets/javascripts/main-utils.js'

#----------------------------------------
# Global Config

jsdom
  skipWindowCheck: true

global.expect = chai.expect
global.assert = chai.assert
