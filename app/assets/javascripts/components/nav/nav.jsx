import React from 'react';
import createReactClass from 'create-react-class';
import Confetti from 'react-confetti';
import CustomLink from './CustomLink.jsx';
import HamburgerMenu from './hamburger_menu.jsx';
import LanguagePicker from './language_picker.jsx';
import NotificationsBell from './notifications_bell';
import ConsentBanner from './consent_banner';

const Nav = createReactClass({
  displayName: 'Nav',

  getInitialState() {
    const navRoot = document.getElementById('nav_root');
    const rootUrl = navRoot.dataset.rooturl;
    const logoPath = navRoot.dataset.logopath;
    const fluid = navRoot.dataset.fluid === 'true'; //  converts string to boolean
    const exploreUrl = navRoot.dataset.exploreurl;
    const exploreName = navRoot.dataset.explorename;
    const userSignedIn = navRoot.dataset.usersignedin === 'true';
    const ifAdmin = navRoot.dataset.ifadmin === 'true';
    const trainingUrl = navRoot.dataset.trainingurl;
    const helpDisabled = navRoot.dataset.help_disabled === 'true';
    const userPermissions = navRoot.dataset.user_permissions === 'true';
    const wikiEd = navRoot.dataset.wiki_ed === 'true';
    const languageSwitcherEnabled = navRoot.dataset.language_switcher_enabled !== ''; // returns boolean false for empty string and true otherwise.
    const currentUser = navRoot.dataset.username;
    const destroyUrl = navRoot.dataset.destroyurl;
    const omniauthUrl = navRoot.dataset.omniauth_url;

    return {
      rootUrl: rootUrl,
      logoPath: logoPath,
      fluid: fluid,
      exploreUrl: exploreUrl,
      exploreName: exploreName,
      userSignedIn: userSignedIn,
      ifAdmin: ifAdmin,
      trainingUrl: trainingUrl,
      helpDisabled: helpDisabled,
      wikiEd: wikiEd,
      userPermissions: userPermissions,
      languageSwitcherEnabled: languageSwitcherEnabled,
      currentUser: currentUser,
      destroyUrl: destroyUrl,
      omniauthUrl: omniauthUrl,
      width: window.innerWidth,
      height: window.innerHeight
    };
  },

  componentDidMount() {
    this.updateDimensions();
    window.addEventListener('resize', this.updateDimensions);
  },

  componentWillUnmount() {
    window.removeEventListener('resize', this.updateDimensions);
  },

  updateDimensions() {
    this.setState({ width: window.innerWidth, height: window.innerHeight });
  },

  showSettings(event) {
    event.preventDefault();
  },

  isCoursePage() {
    return !!this.props.history.location.pathname.match(/courses/);
  },

  render() {
    let navBar;
    let navClass;
    let explore;
    let myDashboard;
    let forAdmin;
    let training;
    let notifications;
    let help;
    let Sandbox;
    let wikiEd;
    let languageSwitcherEnabled;
    let loginLinks;
    let helpEnabled;
    let consentBanner;
    if (this.state.languageSwitcherEnabled) {
      languageSwitcherEnabled = (
        <li>
          <LanguagePicker />
        </li>
      );
    }
    if (this.state.userSignedIn) {
      if (this.state.ifAdmin) {
        notifications = (
          <NotificationsBell />
        );
      }
      loginLinks = (
        <span>
          <li>
            <b><a href={`/users/${this.state.currentUser}`} className="current-user">{this.state.currentUser}</a></b>
          </li>
          { notifications }
          <li>
            <a href={this.state.destroyUrl} className="current-user">{I18n.t('application.log_out')}</a>
          </li>
        </span>
      );
      if (!this.state.helpDisabled) {
        helpEnabled = (
          <div className="top-nav__faq-search">
            <form target="_blank" action="/faq" acceptCharset="UTF-8" method="get">
              <input name="utf8" type="hidden" defaultValue="✓" />
              <input type="text" name="search" id="search" defaultValue="" placeholder={I18n.t('application.search')} />
              <input name="source" type="hidden" defaultValue="nav_ask_form" />
              <button type="submit">
                <i className="icon icon-search" />
              </button>
            </form>
          </div>
      );
      }
    } else {
      loginLinks = (
        <li>
          <a href={this.state.omniauthUrl}>
            <i className="icon icon-wiki-logo" />
            {I18n.t('application.log_in')}
            <span className="expand">
              &nbsp;{I18n.t('application.sign_up_log_in_extended')}
            </span>
          </a>
        </li>
      );
    }
    if (!this.isCoursePage()) {
      explore = (
        <li>
          <CustomLink to={this.state.exploreUrl} name={this.state.exploreName} clickedElement="explore" />
        </li>
      );
    }
    if (!this.isCoursePage() || !Features.wikiEd) {
      training = (
        <li>
          <CustomLink to={this.state.trainingUrl} name={I18n.t('application.training')} clickedElement="training" />
        </li>
      );
    }
    if (this.state.userSignedIn) {
      myDashboard = (
        <li>
          <CustomLink to={this.state.rootUrl} name={I18n.t('application.my_dashboard')} clickedElement="" />
        </li>
      );
    }
    if (this.state.ifAdmin && this.state.wikiEd) {
      forAdmin = (
        <li>
          <CustomLink to="/admin" name="Admin" />
        </li>
      );
    }
    if ((this.state.userSignedIn || this.state.helpDisabled) === false) {
      help = (
        <li>
          <CustomLink to="/faq" name={I18n.t('application.help')} />
        </li>
      );
    }
    if (this.state.userPermissions) {
      Sandbox = (
        <li>
          <CustomLink to="/redirect/sandbox/sandbox" name="My Sandbox" />
        </li>
      );
    }
    if (!this.state.wikiEd) {
      wikiEd = (
        <span id="span_wikied">
          <li>
            <CustomLink to="https://meta.wikimedia.org/wiki/Special:MyLanguage/Programs_%26_Events_Dashboard" name={I18n.t('application.documentation')} target="_blank" />
          </li>
          <li>
            <CustomLink to="https://meta.wikimedia.org/w/index.php?title=Talk:Programs_%26_Events_Dashboard&action=edit&section=new" name={I18n.t('application.report_problem')} target="_blank" />
          </li>
        </span>
      );
    }

    if (Features.consentBanner) {
      consentBanner = <ConsentBanner />;
    }
    if (this.state.fluid) {
      navClass = 'top-nav fluid';
    } else {
      navClass = 'top-nav';
    }
    if (this.state.width < 920) {
      navBar = (
        <div>
          <HamburgerMenu
            rootUrl = {this.state.rootUrl}
            logoPath = {this.state.logoPath}
            exploreUrl = {this.state.exploreUrl}
            exploreName = {this.state.exploreName}
            userSignedIn = {this.state.userSignedIn}
            ifAdmin = {this.state.ifAdmin}
            trainingUrl = {this.state.trainingUrl}
            helpDisabled = {this.state.helpDisabled}
            wikiEd = {this.state.wikiEd}
            userPermissions = {this.state.userPermissions}
            languageSwitcherEnabled = {this.state.languageSwitcherEnabled}
            currentUser = {this.state.currentUser}
            destroyUrl = {this.state.destroyUrl}
            omniauthUrl = {this.state.omniauthUrl}
          />
        </div>
      );
    } else {
      navBar = (
        <div>
          <nav className= {navClass}>
            <div className="container">
              <div className="top-nav__site-logo">
                <a className="logo__link" href= {this.state.rootUrl}>
                  <img src ={this.state.logoPath} alt = "wiki logo" />
                </a>
              </div>
              <ul className="top-nav__main-links">
                {explore}
                {myDashboard}
                {forAdmin}
                {training}
                {Sandbox}
                {help}
                {wikiEd}
              </ul>
              {helpEnabled}
              <ul className="top-nav__login-links">
                {languageSwitcherEnabled}
                {loginLinks}
              </ul>
            </div>
          </nav>
        </div>
      );
    }

    let confetti;
    if (Features.celebrate) {
      confetti = <Confetti width={this.state.width} height={this.state.height} recycle={false} />;
    }

    return (
      <div>
        {confetti}
        {navBar}
        {consentBanner}
      </div>
    );
  }
});

export default Nav;
