import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import _ from 'lodash';

import PopoverExpandable from '../high_order/popover_expandable.jsx';
import Popover from '../common/popover.jsx';
import Conditional from '../high_order/conditional.jsx';
import ServerActions from '../../actions/server_actions.js';
import Lookup from '../common/lookup.jsx';
import LookupSelect from '../common/lookup_select.jsx';
import { capitalize } from '../../utils/strings.js';

const PopoverButton = function (Key, ValueKey, Store, New, Items, IsSelect = false) {
  const getState = () => ({ exclude: _.map(Store.getModels(), ValueKey) });
  const format = function (value) {
    const data = {};
    data[Key] = {};
    data[Key][ValueKey] = value;
    return data;
  };
  const component = createReactClass({
    displayName: `${capitalize(Key)}Button`,

    propTypes: {
      course_id: PropTypes.string,
      is_open: PropTypes.bool,
      open: PropTypes.func
    },

    mixins: [Store.mixin],

    getInitialState() {
      return getState();
    },

    getKey() {
      return `${Key}_button`;
    },

    storeDidChange() {
      if (this.refs.entry !== null) {
        const item = this.refs.entry.getValue();
        if (!New(item)) {
          this.refs.entry.clear();
        }
      }
      return this.setState(getState());
    },

    add(e) {
      if (e.preventDefault) { e.preventDefault(); }
      const item = this.refs.entry.getValue();
      if (New(item)) {
        return ServerActions.add(Key, this.props.course_id, format(item));
      }
      return alert(I18n.t('courses.already_exists'));
    },
    remove(itemId) {
      const item = Store.getFiltered({ id: itemId })[0];
      return ServerActions.remove(Key, this.props.course_id, format(item[ValueKey]));
    },
    stop(e) {
      return e.stopPropagation();
    },
    render() {
      let lookup;
      const placeholder = capitalize(Key);
      if (IsSelect) {
        lookup = (
          <LookupSelect
            model={Key}
            exclude={this.state.exclude}
            placeholder={placeholder}
            ref="entry"
            onSubmit={this.add}
          />
        );
      } else {
        lookup = (
          <Lookup
            model={Key}
            exclude={this.state.exclude}
            placeholder={placeholder}
            ref="entry"
            onSubmit={this.add}
          />
        );
      }
      const editRow = (
        <tr className="edit">
          <td>
            <form onSubmit={this.add}>
              {lookup}
              <button type="submit" className="button border">Add</button>
            </form>
          </td>
        </tr>
      );

      return (
        <div className="pop__container" onClick={this.stop}>
          <button className="button border plus" onClick={this.props.open}>+</button>
          <Popover
            is_open={this.props.is_open}
            edit_row={editRow}
            rows={Items(this.props, this.remove)}
          />
        </div>
      );
    }
  }
  );
  return Conditional(PopoverExpandable(component));
};


export default PopoverButton;
