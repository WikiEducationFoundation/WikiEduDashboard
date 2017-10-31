import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import _ from 'lodash';

import LookupStore from '../../stores/lookup_store.js';

const LookupWrapper = function (Component) {
  const getState = (model, exclude) =>
    ({
      models: _.difference(LookupStore.getLookups(model), exclude),
      submitting: false
    })
  ;
  return createReactClass({
    displayName: 'LookupWrapper',

    propTypes: {
      model: PropTypes.string,
      exclude: PropTypes.array
    },

    mixins: [LookupStore.mixin],

    getInitialState() {
      return getState(this.props.model, this.props.exclude);
    },

    componentWillReceiveProps(newProps) {
      return this.setState(getState(newProps.model, newProps.exclude));
    },

    getValue() {
      return this.refs.entry.getValue();
    },

    storeDidChange() {
      return this.setState(getState(this.props.model, this.props.exclude));
    },

    clear() {
      return this.refs.entry.clear();
    },

    render() {
      return (
        <Component {...this.props} {...this.state} ref="entry" />
      );
    }
  }
  );
};

export default LookupWrapper;
