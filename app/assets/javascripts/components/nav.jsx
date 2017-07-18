import React from 'react';
import { slide as Menu } from 'react-burger-menu';
const Nav = React.createClass({
  displayName: 'Nav',

  propTypes: {
    rootUrl: React.PropTypes.string
  },

  getInitialState() {
    return {
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
    console.log(this.props.rootUrl);
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
          <nav className="fluid top-nav">
            <div className="container">
              <div className="top-nav__site-logo">
                <a className="logo__link" href= {this.props.rootUrl}>
                  bfhvbhfbv
                </a>
              </div>
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
