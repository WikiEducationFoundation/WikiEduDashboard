import React from 'react';
import { slide as Menu } from 'react-burger-menu';
import CustomLink from './CustomLink.jsx';

const HamburgerMenu = React.createClass({
  propTypes: {
    rootUrl: React.PropTypes.string,
    logoPath: React.PropTypes.string,
    fluid: React.PropTypes.bool,
    exploreclass: React.PropTypes.string,
    exploreurl: React.PropTypes.string,
    explorename: React.PropTypes.string,
    usersignedin: React.PropTypes.bool,
    ifadmin: React.PropTypes.bool,
    trainingurl: React.PropTypes.string,
    disableTraining: React.PropTypes.bool,
    helpDisabled: React.PropTypes.bool,
    askUrl: React.PropTypes.string,
    wikiEd: React.PropTypes.bool,
    userPermissions: React.PropTypes.bool,
    languageSwitcherEnabled: React.PropTypes.bool,
    currentUser: React.PropTypes.string,
    destroyUrl: React.PropTypes.string,
    omniauthUrl: React.PropTypes.string
  },
  render() {
    let myDashboard;
    let forAdmin;
    let disableTraining;
    let help;
    let Sandbox;
    let wikiEd;
    let languageSwitcherEnabled;
    let loggingLinks;
    let helpEnabled;
    if (this.props.languageSwitcherEnabled)
    {
      languageSwitcherEnabled = (
        <li>
          <button className="uls-trigger">
            {I18n.locale}
          </button>
        </li>
      );
    }
    if (this.props.usersignedin)
    {
      loggingLinks = (
        <span>
          <li>
            <b><a href={this.props.rootUrl} className="current-user">{this.props.currentUser}</a></b>
          </li>
          <li>
            <a href={this.props.destroyUrl} className="current-user">{I18n.t('application.log_out')}</a>
          </li>
        </span>
      );
      if (!this.props.helpDisabled) {
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
          <a href={this.props.omniauthUrl}>
            <i className="icon icon-wiki-logo"></i>
            {I18n.t('application.log_in')}
            <span className="expand">
              {I18n.t('application.sign_up_log_in_extended')}
            </span>
          </a>
        </li>
      );
    }
    if (this.props.usersignedin === true) {
      myDashboard = (
        <li>
          <CustomLink to={this.props.rootUrl} name={I18n.t('application.my_dashboard')} clickedElement="" />
        </li>
      );
    }
    if (this.props.ifadmin === true) {
      forAdmin = (
        <li>
          <CustomLink to="/admin" name="Admin" />
        </li>
      );
    }
    if (this.props.disableTraining === false) {
      disableTraining = (
        <li>
          <CustomLink to={this.props.trainingurl} name={I18n.t('application.training')} clickedElement="training" />
        </li>
      );
    }
    if ((this.props.usersignedin || this.props.helpDisabled) === false) {
      help = (
        <li>
          <CustomLink to={this.props.askUrl} name={I18n.t('application.help')} />
        </li>
      );
    }
    if (this.props.userPermissions) {
      Sandbox = (
        <li>
          <CustomLink to="https://en.wikipedia.org/wiki/Special:MyPage/sandbox" name="My Sandbox" />
        </li>
      );
    }
    if (!this.props.wikiEd) {
      wikiEd = (
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
        <Menu>
          <CustomLink to={this.props.exploreurl} name={this.props.explorename} clickedElement="explore" />
          {myDashboard}
          {forAdmin}
          {disableTraining}
          {Sandbox}
          {help}
          {wikiEd}
          {helpEnabled}
          {languageSwitcherEnabled}
          {loggingLinks}
        </Menu>
      </div>
    );
  }
});

export default HamburgerMenu;
