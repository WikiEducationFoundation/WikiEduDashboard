import React from 'react';
import PropTypes from 'prop-types';
import { slide as Menu } from 'react-burger-menu';
import CustomLink from './CustomLink.jsx';

const HamburgerMenu = ({ rootUrl, logoPath, exploreUrl, exploreName, userSignedIn, ifAdmin, trainingUrl, helpDisabled, askUrl, wikiEd, userPermissions, languageSwitcherEnabled, currentUser, destroyUrl, omniauthUrl }) => {
  let myDashboard;
  let forAdmin;
  let help;
  let sandbox;
  let programsDashboard;
  let languageSwitcher;
  let loggingLinks;
  let helpEnabled;
  if (languageSwitcherEnabled)
  {
    languageSwitcher = (
      <li>
        <button className="uls-trigger">
          {I18n.locale}
        </button>
      </li>
    );
  }
  if (userSignedIn)
  {
    loggingLinks = (
      <span>
        <li>
          <b><a href={rootUrl} className="current-user">{currentUser}</a></b>
        </li>
        <li>
          <a href={destroyUrl} className="current-user">{I18n.t('application.log_out')}</a>
        </li>
      </span>
    );
    if (!helpDisabled) {
      helpEnabled = (
        <div className="top-nav__faq-search">
          <form target="_blank" action="/ask" acceptCharset="UTF-8" method="get">
            <input name="utf8" type="hidden" defaultValue="✓" />
            <input type="text" name="q" id="q" defaultValue="" placeholder={I18n.t('application.search')} />
            <input name="source" type="hidden" defaultValue="nav_ask_form" />
            <button type="submit">
              <i className="icon icon-search" />
            </button>
          </form>
        </div>
    );
    }
  } else {
    loggingLinks = (
      <li>
        <a href={omniauthUrl}>
          <i className="icon icon-wiki-logo" />
          {I18n.t('application.log_in')}
          <span className="expand">
            &nbsp;{I18n.t('application.sign_up_log_in_extended')}
          </span>
        </a>
      </li>
    );
  }
  if (userSignedIn === true) {
    myDashboard = (
      <li>
        <CustomLink to={rootUrl} name={I18n.t('application.my_dashboard')} clickedElement="" />
      </li>
    );
  }
  if (ifAdmin === true) {
    forAdmin = (
      <li>
        <CustomLink to="/admin" name="Admin" />
      </li>
    );
  }
  if ((userSignedIn || helpDisabled) === false) {
    help = (
      <li>
        <CustomLink to={askUrl} name={I18n.t('application.help')} />
      </li>
    );
  }
  if (userPermissions) {
    sandbox = (
      <li>
        <CustomLink to="https://en.wikipedia.org/wiki/Special:MyPage/sandbox" name="My Sandbox" />
      </li>
    );
  }
  if (!wikiEd) {
    programsDashboard = (
      <span id="span_wikied">
        <li>
          <CustomLink to="https://meta.wikimedia.org/wiki/Programs_%26_Events_Dashboard" name={I18n.t('application.documentation')} target="_blank" />
        </li>
        <li>
          <CustomLink to="/feedback" name={I18n.t('application.report_problem')} target="_blank" />
        </li>
      </span>
    );
  }
  return (
    <div>
      <nav className="ham-nav">
        <div className="container">
          <div className="ham-nav__site-logo">
            <a className="logo__link" href= {rootUrl}>
              <img src ={logoPath} alt = "wiki logo" />
            </a>
          </div>
          {languageSwitcher}
          <div className="hamburger_menu_wrapper">
            <Menu right>
              <CustomLink to={exploreUrl} name={exploreName} clickedElement="explore" />
              {myDashboard}
              {forAdmin}
              <li>
                <CustomLink to={trainingUrl} name={I18n.t('application.training')} clickedElement="training" />
              </li>
              {sandbox}
              {help}
              {programsDashboard}
              {helpEnabled}
              {loggingLinks}
            </Menu>
          </div>
        </div>
      </nav>
    </div>
  );
};


HamburgerMenu.propTypes = {
  rootUrl: PropTypes.string,
  logoPath: PropTypes.string,
  exploreUrl: PropTypes.string,
  exploreName: PropTypes.string,
  userSignedIn: PropTypes.bool,
  ifAdmin: PropTypes.bool,
  trainingUrl: PropTypes.string,
  helpDisabled: PropTypes.bool,
  askUrl: PropTypes.string,
  wikiEd: PropTypes.bool,
  userPermissions: PropTypes.bool,
  languageSwitcherEnabled: PropTypes.bool,
  currentUser: PropTypes.string,
  destroyUrl: PropTypes.string,
  omniauthUrl: PropTypes.string
};

export default HamburgerMenu;
