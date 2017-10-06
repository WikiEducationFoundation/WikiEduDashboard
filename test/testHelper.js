const jsdom = require('jsdom');

global.document = jsdom.jsdom("<!doctype html><html><body><div data-current_user='{ \"admin\": false, \"id\": null }' id='react_root'></div></body></html>", {
  url: 'http://localhost',
  skipWindowCheck: true
});
global.window = document.defaultView;
global.navigator = global.window.navigator;


const sinon = require('sinon');
const React = require('react');
const ReactDOM = require('react-dom');
const ReactTestUtils = require('react-addons-test-utils');
const $ = require('jquery');
const _ = require('lodash');
const moment = require('moment');
const momentRecur = require('moment-recur');
const I18n = require('../public/assets/javascripts/i18n.js'); // eslint-disable-line import/no-unresolved
const chai = require('chai');
const sinonChai = require('sinon-chai');

import { createStore, applyMiddleware } from 'redux';
import thunk from 'redux-thunk';
import reducer from '../app/assets/javascripts/reducers';

const reduxStore = createStore(reducer, applyMiddleware(thunk));

global.reduxStore = reduxStore;
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
global.Features = {};

require('../public/assets/javascripts/i18n/en'); // eslint-disable-line import/no-unresolved

chai.use(sinonChai);
