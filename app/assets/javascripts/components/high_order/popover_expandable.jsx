import React from 'react';
import createReactClass from 'create-react-class';
import { connect } from 'react-redux';
import OnClickOutside from 'react-onclickoutside';
import { toggleUI } from '../../actions';
import Conditional from '../high_order/conditional.jsx';

// This is a variant version of Expandable which closes upon
// outside click. Use Expandable where the 'open' state should
// persist until it is explicitly closed, and use this
// for popover buttons and other situations where users would
// expect a click elsewhere to toggle the state.

const mapStateToProps = state => ({
  openKey: state.ui.openKey
});

const mapDispatchToProps = {
  toggleUI
};

const PopoverExpandable = function (Component) {
  const wrappedComponent = createReactClass({
    displayName: 'PopoverExpandable',

    statics: {
      getDerivedStateFromProps(props, state) {
        return {
          is_open: state.key === props.openKey
        };
      }
    },

    getInitialState() {
      return { is_open: false };
    },

    componentDidMount() {
      this.setState({
        key: this.refs.component.getKey()
      });
    },

    open() {
      return this.props.toggleUI(this.refs.component.getKey());
    },

    handleClickOutside(e) {
      if (this.state.is_open) this.open(e);
    },

    render() {
      return (
        <Component
          {...this.state}
          {...this.props}
          open={this.open}
          stop={this.stop}
          ref={'component'}
        />
      );
    }
  });
  return connect(mapStateToProps, mapDispatchToProps)(Conditional(OnClickOutside(wrappedComponent)));
};

export default PopoverExpandable;
