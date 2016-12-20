import React from 'react';
import UIActions from '../../actions/ui_actions.js';
import UIStore from '../../stores/ui_store.js';
import OnClickOutside from 'react-onclickoutside';
import Conditional from '../high_order/conditional.jsx';

const Expandable = function (Component) {
  const component = React.createClass({
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

    handleClickOutside() {
      // TODO: Fire UIActions.close?
      this.setState({
        is_open: false
      });
    },

    render() {
      return (
        <Component {...this.state} {...this.props}
          open={this.open}
          stop={this.stop}
          ref={'component'}
        />
      );
    }
  });
  return Conditional(OnClickOutside(component));
};

export default Expandable;
