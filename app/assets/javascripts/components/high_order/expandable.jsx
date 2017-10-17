import React from 'react';
import createReactClass from 'create-react-class';
import UIActions from '../../actions/ui_actions.js';
import UIStore from '../../stores/ui_store.js';

const Expandable = function (Component) {
  return createReactClass({
    displayName: 'Expandable',
    mixins: [UIStore.mixin],

    getInitialState() {
      return { is_open: false };
    },

    storeDidChange() {
      this.setState({
        is_open: UIStore.getOpenKey() === this.refs.component.getKey()
      });
    },

    open(e) {
      if (e !== null) { e.stopPropagation(); }
      return UIActions.open(this.refs.component.getKey());
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
};

export default Expandable;
