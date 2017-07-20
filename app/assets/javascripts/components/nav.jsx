import React from 'react';
import { slide as Menu } from 'react-burger-menu';
const Nav = React.createClass({
  displayName: 'Nav',

  getInitialState() {
    const rootUrl = $('#nav_root').data('rooturl');
    const logoPath = $('#nav_root').data('logopath');
    const fluid = $('#nav_root').data('fluid');
    const exploreurl = $('#nav_root').data('exploreurl');
    const explorename = $('#nav_root').data('explorename');
    const classs = $('#nav_root').data('classs');
    console.log(rootUrl);
    console.log(logoPath);
    console.log(fluid);
    console.log(exploreurl);
    console.log(explorename);
    console.log(classs);
    return {
      rootUrl: rootUrl,
      logoPath: logoPath,
      fluid: fluid,
      exploreurl: exploreurl,
      explorename: explorename,
      width: $(window).width(),
      height: $(window).height()
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
    console.log(this.state.rootUrl);
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
                  <a href = {this.state.exploreurl}>
                    {this.state.explorename}
                  </a>
                </li>
              </ul>
              <ul className="top-nav__login-links">
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
