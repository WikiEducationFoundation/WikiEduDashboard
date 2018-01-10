import React from 'react';
import createReactClass from 'create-react-class';
import { connect } from 'react-redux';
import { toggleUI, resetUI } from '../../actions';

const mapStateToProps = state => ({
  openKey: state.ui.openKey
});

const mapDispatchToProps = {
  toggleUI,
  resetUI
};

const Expandable = function (Component) {
  const wrappedComponent = createReactClass({
    displayName: 'Expandable',

    componentWillReceiveProps(props) {
      this.setState({
        is_open: this.refs.component.getKey() === props.openKey
      });
    },

    open(e) {
      if (e !== null) { e.stopPropagation(); }
      return this.props.toggleUI(this.refs.component.getKey());
    },

    render() {
      return (
        <Component
          {...this.state} {...this.props}
          open={this.open}
          stop={this.stop}
          ref={'component'}
        />
      );
    }
  });
  return connect(mapStateToProps, mapDispatchToProps)(wrappedComponent);
};

export default Expandable;
