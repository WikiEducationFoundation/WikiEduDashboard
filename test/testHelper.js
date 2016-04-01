const jsdom = require('mocha-jsdom');
const testdom = require('testdom');
global.testdom = testdom('<html><body><div></div></body></html>');


const sinon = require('sinon');
const React = require('react');
const ReactDOM = require('react-dom');
const ReactTestUtils = require('react-addons-test-utils');
const $ = require('jquery');
const _ = require('lodash');
const moment = require('moment');
const momentRecur = require('moment-recur');
const I18n = require('../public/assets/javascripts/i18n.js');
const chai = require('chai');

global.$ = $;
global._ = _;
global.sinon = sinon;
global.React = React;
global.ReactDOM = ReactDOM;
global.ReactTestUtils = ReactTestUtils;
global.Simulate = ReactTestUtils.Simulate;
global.moment = moment;
global['moment-recur'] = momentRecur;
global.I18n = I18n;
global.chai = chai;
global.expect = chai.expect;
global.assert = chai.assert;

jsdom({ skipWindowCheck: true });
