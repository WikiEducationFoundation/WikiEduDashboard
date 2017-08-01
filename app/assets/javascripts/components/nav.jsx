import React from 'react';
// import { Link } from 'react-router';
import { slide as Menu } from 'react-burger-menu';
import CustomLink from './CustomLink.jsx';
const Nav = React.createClass({
  displayName: 'Nav',

  getInitialState() {
    const rootUrl = $('#nav_root').data('rooturl');
    const logoPath = $('#nav_root').data('logopath');
    const fluid = $('#nav_root').data('fluid');
    const exploreurl = $('#nav_root').data('exploreurl');
    const explorename = $('#nav_root').data('explorename');
    const exploreclass = $('#nav_root').data('exploreclass');
    const usersignedin = $('#nav_root').data('usersignedin');
    const ifadmin = $('#nav_root').data('ifadmin');
    const trainingurl = $('#nav_root').data('trainingurl');
    const disableTraining = $('#nav_root').data('disable_training');
    const helpDisabled = $('#nav_root').data('help_disabled');
    const askUrl = $('#nav_root').data('ask_url');
    const userPermissions = $('#nav_root').data('user_permissions');
    const wikiEd = $('#nav_root').data('wiki_ed');
    const languageSwitcherEnabled = $('#nav_root').data('language_switcher_enabled');
    const currentUser = $('#nav_root').data('username');
    const destroyUrl = $('#nav_root').data('destroyurl');
    const omniauthUrl = $('#nav_root').data('omniauth_url');

    return {
      rootUrl: rootUrl,
      logoPath: logoPath,
      fluid: fluid,
      exploreclass: exploreclass,
      exploreurl: exploreurl,
      explorename: explorename,
      usersignedin: usersignedin,
      ifadmin: ifadmin,
      trainingurl: trainingurl,
      disableTraining: disableTraining,
      helpDisabled: helpDisabled,
      askUrl: askUrl,
      wikiEd: wikiEd,
      userPermissions: userPermissions,
      languageSwitcherEnabled: languageSwitcherEnabled,
      currentUser: currentUser,
      destroyUrl: destroyUrl,
      omniauthUrl: omniauthUrl,
      width: $(window).width(),
      height: $(window).height(),
      query: ""
    };
  },

  componentWillMount() {
    this.updateDimensions();
  },

  componentDidMount() {
    window.addEventListener("resize", this.updateDimensions);
  },
  componentWillUnmount() {
    window.removeEventListener("resize", this.updateDimensions);
  },

  updateDimensions() {
    this.setState({ width: $(window).width(), height: $(window).height() });
  },

  showSettings(event) {
    event.preventDefault();
  },

  render() {
    let navBar;
    let navClass;
    let myDashboard;
    let forAdmin;
    let disableTraining;
    let help;
    let Sandbox;
    let wikiEd;
    let languageSwitcherEnabled;
    let loggingLinks;
    let helpEnabled;
    if (this.state.languageSwitcherEnabled)
    {
      languageSwitcherEnabled = (
        <li>
          <button className="uls-trigger">
            {I18n.locale}
          </button>
        </li>
      );
    }
    if (this.state.usersignedin)
    {
      loggingLinks = (
        <span>
          <li>
            <b><a href={this.state.rootUrl} className="current-user">{this.state.currentUser}</a></b>
          </li>
          <li>
            <a href={this.state.destroyUrl} className="current-user">{I18n.t('application.log_out')}</a>
          </li>
        </span>
      );
      if (!this.state.helpDisabled) {
        helpEnabled = (
          <div className="top-nav__faq-search">
            <form target="_blank" action="/ask" acceptCharset="UTF-8" method="get">
              <input name="utf8" type="hidden" defaultValue="✓" />
              <input type="text" name="q" id="q" defaultValue="" placeholder={I18n.t('application.search')} />
              <input name="source" type="hidden" defaultValue="nav_ask_form" />
              <button type="submit">
                <i className="icon icon-search"></i>
              </button>
            </form>
          </div>
      );
      }
    } else {
      loggingLinks = (
        <li>
          <a href={this.state.omniauthUrl}>
            <i className="icon icon-wiki-logo"></i>
            {I18n.t('application.log_in')}
            <span className="expand">
              {I18n.t('application.sign_up_log_in_extended')}
            </span>
          </a>
        </li>
      );
    }
    if (this.state.usersignedin === true) {
      myDashboard = (
        <li>
          <CustomLink to={this.state.rootUrl} activeClassName="active" name={I18n.t('application.my_dashboard')} clickedElement="" />
        </li>
      );
    }
    if (this.state.ifadmin === true) {
      forAdmin = (
        <li>
          <CustomLink to="/admin" activeClassName="active" name = "Admin" />
        </li>
      );
    }
    if (this.state.disableTraining === false) {
      disableTraining = (
        <li>
          <CustomLink to={this.state.trainingurl} activeClassName="active">{I18n.t('application.training')}</CustomLink>
        </li>
      );
    }
    if ((this.state.usersignedin || this.state.helpDisabled) === false) {
      help = (
        <li>
          <CustomLink to={this.state.askUrl} activeClassName="active">{I18n.t('application.help')}</CustomLink>
        </li>
      );
    }
    if (this.state.userPermissions) {
      Sandbox = (
        <li>
          <CustomLink to="https://en.wikipedia.org/wiki/Special:MyPage/sandbox" activeClassName="active">My Sandbox</CustomLink>
        </li>
      );
    }
    if (!this.state.wikiEd) {
      wikiEd = (
        <span id="span_wikied">
          <li>
            <CustomLink to="https://meta.wikimedia.org/wiki/Programs_%26_Events_Dashboard" activeClassName="active">{I18n.t('application.documentation')}</CustomLink>
          </li>
          <li>
            <CustomLink to="/feedback" activeClassName="active">{I18n.t('application.report_problem')}</CustomLink>
          </li>
        </span>
      );
    }
    if (this.state.fluid)
    {
      navClass = "top-nav fluid";
    } else {
      navClass = "top-nav";
    }
    if (this.state.width < 500)
    {
      navBar = (
        <div>
          <span>{this.state.width} x {this.state.height} </span>
          <Menu>
            <a id="home" className="menu-item" href="/">Home</a>
            <a id="about" className="menu-item" href="/about">About</a>
            <a id="contact" className="menu-item" href="/contact">Contact</a>
          </Menu>
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
                <li>
                  <CustomLink to={this.state.exploreurl} activeClassName="active" name={this.state.explorename} clickedElement="explore" />
                </li>
                {myDashboard}
                {forAdmin}
                {disableTraining}
                {Sandbox}
                {help}
                {wikiEd}
                {helpEnabled}
              </ul>
              <ul className="top-nav__login-links">
                {languageSwitcherEnabled}
                {loggingLinks}
              </ul>
            </div>
          </nav>
        </div>
      );
    }

    return (
      <div>
        {navBar}
      </div>
    );
  }
});

export default Nav;
