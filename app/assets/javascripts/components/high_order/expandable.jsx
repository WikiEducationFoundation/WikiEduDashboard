import React from 'react';
import createReactClass from 'create-react-class';
import { connect } from 'react-redux';
import { toggleUI } from '../../actions';

const mapStateToProps = state => ({
  openKey: state.ui.openKey
});

const mapDispatchToProps = {
  toggleUI
};

const Expandable = function (Component) {
  const wrappedComponent = createReactClass({
    displayName: 'Expandable',

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
