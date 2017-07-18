import React from 'react';
import { slide as Menu } from 'react-burger-menu';

class Nav extends React.Component {

  componentWillMount() {
    this.updateDimensions();
  }

  componentDidMount() {
    window.addEventListener("resize", this.updateDimensions);
  }
  componentWillUnmount() {
    window.removeEventListener("resize", this.updateDimensions);
  }

  updateDimensions() {
    this.setState({ width: $(window).width(), height: $(window).height() });
  }

  showSettings(event) {
    event.preventDefault();
  }

  render() {
    let navBar;
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
}
Nav.propTypes = {
  main_app: React.PropTypes.string
};
export default Nav;
