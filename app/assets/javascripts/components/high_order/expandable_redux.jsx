import React from 'react';
import UIActions from '../../actions/ui_actions.js';

const ExpandableRedux = function (Component) {
  return React.createClass({
    displayName: 'ExpandableRedux',

    propTypes: {
      reduxState: React.PropTypes.object
    },

    isOpen() {
      if (!this.refs.component) { return false; }
      return this.props.reduxState.openKey === this.refs.component.getKey();
    },

    open(e) {
      if (e !== null) { e.stopPropagation(); }
      return UIActions.open(this.refs.component.getKey());
    },

    render() {
      return (
        <Component {...this.props}
          isOpen={this.isOpen()}
          open={this.open}
          stop={this.stop}
          ref={'component'}
        />
      );
    }
  });
};

export default ExpandableRedux;
