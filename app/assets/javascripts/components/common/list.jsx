import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import Loading from './loading.jsx';
import UIActions from '../../actions/ui_actions.js';

const List = createReactClass({
  displayName: 'List',

  propTypes: {
    store: PropTypes.object,
    keys: PropTypes.object,
    sortable: PropTypes.bool,
    table_key: PropTypes.string,
    className: PropTypes.string,
    elements: PropTypes.node,
    none_message: PropTypes.string
  },

  render() {
    const sorting = this.props.store.getSorting();
    const sortClass = sorting.asc ? 'asc' : 'desc';
    const headers = [];
    const iterable = Object.keys(this.props.keys);
    for (let i = 0; i < iterable.length; i++) {
      const key = iterable[i];
      const keyObj = this.props.keys[key];
      let headerOnClick;
      let headerClass = sorting.key === key ? sortClass : '';
      let tooltip;
      headerClass += keyObj.desktop_only ? ' desktop-only-tc' : '';
      if ((this.props.sortable !== false) && (keyObj.sortable !== false)) {
        headerClass += ' sortable';
        headerOnClick = UIActions.sort.bind(null, this.props.table_key, key);
      }
      if (keyObj.info_key) {
        headerClass += ' tooltip-trigger';
        tooltip = [(
          <div key="tt" className="tooltip dark">
            <p>{I18n.t(keyObj.info_key)}</p>
          </div>
        ), (
          <span key="ttindicator" className="tooltip-indicator" />
        )];
      }
      headers.push((
        <th onClick={headerOnClick} className={headerClass} key={key}>
          <span dangerouslySetInnerHTML={{ __html: keyObj.label }} />
          <span className="sortable-indicator" />
          {tooltip}
        </th>
      ));
    }


    let className = `${this.props.table_key} table `;

    if (this.props.className) { className += this.props.className; }

    if (this.props.sortable) { className += ' table--sortable'; }

    let { elements } = this.props;

    // Handle the case of no elements:
    // Show a none message if data is already loaded, or
    // show the Loading spinner if data is not yet loaded.
    if (elements.length === 0) {
      let emptyMessage;
      if (this.props.store.isLoaded()) {
        let noneMessage = this.props.none_message;
        if (typeof noneMessage === 'undefined' || noneMessage === null) {
          noneMessage = I18n.t(`${this.props.table_key}.none`);
        }
        emptyMessage = <span>{noneMessage}</span>;
      } else {
        emptyMessage = <Loading />;
      }
      elements = (
        <tr className="disabled">
          <td colSpan={headers.length + 1} className="text-center">
            {emptyMessage}
          </td>
        </tr>
      );
    }

    return (
      <table className={className}>
        <thead>
          <tr>
            {headers}
            <th />
          </tr>
        </thead>
        <tbody>
          {elements}
        </tbody>
      </table>
    );
  }
}
);

export default List;
