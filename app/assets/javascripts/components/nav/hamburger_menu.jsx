import React, { useState } from 'react';
import PropTypes from 'prop-types';
import CustomLink from './CustomLink.jsx';
import LanguagePicker from './language_picker.jsx';

const HamburgerMenu = ({ rootUrl, logoPath, exploreUrl, exploreName, userSignedIn, ifAdmin, trainingUrl,
  helpDisabled, wikiEd, languageSwitcherEnabled, currentUser, destroyUrl, omniauthUrl }) => {
  const [isActive, setIsActive] = useState(false);

  const toggleClass = () => {
    setIsActive(!isActive);
  };

  return (
    <div>
      <nav className="ham-nav">
        <div className="container">
          <div className="ham-nav__site-logo">
            <a className="logo__link" href={rootUrl}>
              <img src={logoPath} alt="wiki logo" />
            </a>
          </div>
          {languageSwitcherEnabled && <LanguagePicker />}
          <div className="hamburger_menu_wrapper">
            <div className="bm-burger-button" onClick={toggleClass}>
              <div className={(isActive) ? 'bm-menu-active' : ''}>
                <div className="bar1" />
                <div className="bar2" />
                <div className="bar3" />
              </div>
            </div>
            <div className={`bm-menu-wrap ${(isActive) ? 'bm-menu-visible' : ''}`}>
              <div className="bm-menu">
                <li>
                  <CustomLink to={exploreUrl} name={exploreName} clickedElement="explore" />
                </li>
                {userSignedIn && (
                  <li>
                    <CustomLink to={rootUrl} name={I18n.t('application.my_dashboard')} clickedElement="" />
                  </li>
                )}
                {ifAdmin && (
                  <li>
                    <CustomLink to="/admin" name="Admin" />
                  </li>
                )}
                <li>
                  <CustomLink to={trainingUrl} name={I18n.t('application.training')} clickedElement="training" />
                </li>
                {((userSignedIn || helpDisabled) === false) && (
                  <li>
                    <CustomLink to="/faq" name={I18n.t('application.help')} />
                  </li>
                )}
                {!wikiEd && (
                  <span id="span_wikied">
                    <li>
                      <CustomLink to="https://meta.wikimedia.org/wiki/Programs_%26_Events_Dashboard" name={I18n.t('application.documentation')} target="_blank" />
                    </li>
                    <li>
                      <CustomLink to="/feedback" name={I18n.t('application.report_problem')} target="_blank" />
                    </li>
                  </span>
                )}
                {userSignedIn && !helpDisabled && (
                  <li>
                    <form className="top-nav__faq-search" target="_blank" action="/faq" acceptCharset="UTF-8" method="get">
                      <input name="utf8" type="hidden" defaultValue="✓" />
                      <input type="text" name="search" id="hamburger_search" defaultValue="" placeholder={I18n.t('application.search')} />
                      <input name="source" type="hidden" defaultValue="nav_ask_form" />
                      <button type="submit">
                        <i className="icon icon-search" />
                      </button>
                    </form>
                  </li>
                )}
                {userSignedIn ? (
                  <span>
                    <li>
                      <b><a href={rootUrl} className="current-user">{currentUser}</a></b>
                    </li>
                    <li>
                      <a href={destroyUrl} className="current-user">{I18n.t('application.log_out')}</a>
                    </li>
                  </span>
                ) : (
                  // This link relies on rails/ujs to turn the anchor link into
                  // a POST request based on data-method="post". Otherwise, this
                  // needs to become a button or form and include the authenticity token.
                  <li>
                    <a data-method="post" href={omniauthUrl}>
                      <i className="icon icon-wiki-logo" />
                      {I18n.t('application.log_in')}
                      <span className="expand">
                        &nbsp;{I18n.t('application.sign_up_log_in_extended')}
                      </span>
                    </a>
                  </li>
                )}
              </div>
            </div>
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
  wikiEd: PropTypes.bool,
  languageSwitcherEnabled: PropTypes.bool,
  currentUser: PropTypes.string,
  destroyUrl: PropTypes.string,
  omniauthUrl: PropTypes.string,
};

export default HamburgerMenu;
