import React, { useEffect, useState } from 'react';
import CustomLink from './CustomLink.jsx';
import HamburgerMenu from './hamburger_menu.jsx';
import LanguagePicker from './language_picker.jsx';
import NotificationsBell from './notifications_bell';
import ConsentBanner from './consent_banner';
import NewsHandler from './news/news_handler.jsx';

const Nav = () => {
  const {
    rooturl: rootUrl,
    logopath: logoPath,
    fluid: fluidStr,
    exploreurl: exploreUrl,
    explorename: exploreName,
    usersignedin: userSignedInStr,
    ifadmin: ifAdminStr,
    trainingurl: trainingUrl,
    help_disabled: helpDisabledStr,
    wiki_ed: wikiEdStr,
    language_switcher_enabled: languageSwitcherEnabledStr,
    username: currentUser,
    destroyurl: destroyUrl,
    omniauth_url: omniauthUrl
  } = document.getElementById('nav_root').dataset;

  const fluid = fluidStr === 'true';
  const userSignedIn = userSignedInStr === 'true';
  const ifAdmin = ifAdminStr === 'true';
  const helpDisabled = helpDisabledStr === 'true';
  const wikiEd = wikiEdStr === 'true';
  const languageSwitcherEnabled = languageSwitcherEnabledStr !== '';

  const [isHovered, setIsHovered] = useState(false);
  const [dimensions, setDimensions] = useState({ width: window.innerWidth, height: window.innerHeight });

  const updateDimensions = () => {
    setDimensions({
      width: window.innerWidth,
      height: window.innerHeight
    });
  };

  useEffect(() => {
    updateDimensions();
    window.addEventListener('resize', updateDimensions);
    return () => {
      window.removeEventListener('resize', updateDimensions);
    };
  }, []);

  const isCoursePage = () => {
    return !!window.location.pathname.match(/courses/);
  };

  const isSmallScreen = dimensions.width < 920;

  return (
    <div>
      {isSmallScreen ? (
        <div>
          <HamburgerMenu
            rootUrl={rootUrl}
            logoPath={logoPath}
            exploreUrl={exploreUrl}
            exploreName={exploreName}
            userSignedIn={userSignedIn}
            ifAdmin={ifAdmin}
            trainingUrl={trainingUrl}
            helpDisabled={helpDisabled}
            wikiEd={wikiEd}
            languageSwitcherEnabled={languageSwitcherEnabled}
            currentUser={currentUser}
            destroyUrl={destroyUrl}
            omniauthUrl={omniauthUrl}
          />
        </div>
      ) : (
        <div>
          <nav className={`top-nav ${fluid ? 'fluid' : ''}`}>
            <div className="container">
              <div className="top-nav__site-logo">
                <a className="logo__link" href={rootUrl}>
                  <img src={logoPath} alt="wiki logo" />
                </a>
              </div>
              <ul className="top-nav__main-links">
                {!isCoursePage() && (
                  <li>
                    <CustomLink to={exploreUrl} name={exploreName} clickedElement="explore" />
                  </li>
                )}
                {userSignedIn && (
                  <li>
                    <CustomLink to={rootUrl} name={I18n.t('application.my_dashboard')} clickedElement="" />
                  </li>
                )}
                {ifAdmin && wikiEd && (
                  <li>
                    <CustomLink to="/admin" name="Admin" />
                  </li>
                )}
                {(!isCoursePage() || !Features.wikiEd) && (
                  <li>
                    <CustomLink to={trainingUrl} name={I18n.t('application.training')} clickedElement="training" />
                  </li>
                )}
                {((userSignedIn || helpDisabled) === false) && (
                  <li>
                    <CustomLink to="/faq" name={I18n.t('application.help')} />
                  </li>
                )}
                {!wikiEd && (
                  <span id="span_wikied">
                    <li>
                      <CustomLink to="https://meta.wikimedia.org/wiki/Special:MyLanguage/Programs_%26_Events_Dashboard" name={I18n.t('application.documentation')} target="_blank" />
                    </li>
                    <li>
                      <CustomLink to="https://meta.wikimedia.org/w/index.php?title=Talk:Programs_%26_Events_Dashboard&action=edit&section=new" name={I18n.t('application.report_problem')} target="_blank" />
                    </li>
                  </span>
                )}
              </ul>
              {userSignedIn && !helpDisabled && (
                <div className="top-nav__faq-search">
                  <form target="_blank" action="/faq" acceptCharset="UTF-8" method="get">
                    <input name="utf8" type="hidden" defaultValue="✓" />
                    <input type="text" name="search" id="nav_search" defaultValue="" placeholder={I18n.t('application.search')} />
                    <input name="source" type="hidden" defaultValue="nav_ask_form" />
                    <button type="submit" className="icon icon-search" />
                  </form>
                </div>
              )}
              <ul className="top-nav__login-links">
                {languageSwitcherEnabled && (
                  <li>
                    <LanguagePicker />
                  </li>
                )}
                {userSignedIn ? (
                  <span>
                    <li>
                      <b><a href={`/users/${encodeURIComponent(currentUser)}`} className="current-user">{currentUser}</a></b>
                    </li>
                    <NewsHandler/>
                    {ifAdmin && <NotificationsBell />}
                    <li>
                      <a href={destroyUrl} className="current-user">{I18n.t('application.log_out')}</a>
                    </li>
                  </span>
                ) : (
                  // This link relies on rails/ujs to turn the anchor link into
                  // a POST request based on data-method="post". Otherwise, this
                  // needs to become a button or form and include the authenticity token.
                  <li>
                    <a data-method="post" href={omniauthUrl} onMouseEnter={() => setIsHovered(true)} onMouseLeave={() => setIsHovered(false)}>
                      <i className={`icon ${isHovered ? ' icon-wiki-purple' : ' icon-wiki'}`} />
                      {I18n.t('application.log_in')}
                      <span className="expand">
                        &nbsp;{I18n.t('application.sign_up_log_in_extended')}
                      </span>
                    </a>
                  </li>
                )}
              </ul>
            </div>
          </nav>
        </div>
      )}
      {Features.consentBanner && <ConsentBanner />}
    </div>
  );
};

export default Nav;
