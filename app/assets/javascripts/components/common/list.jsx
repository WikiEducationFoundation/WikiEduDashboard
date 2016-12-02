import React from 'react';
import UIActions from '../../actions/ui_actions.js';

const List = React.createClass({
  displayName: 'List',

  propTypes: {
    store: React.PropTypes.object,
    keys: React.PropTypes.object,
    sortable: React.PropTypes.bool,
    table_key: React.PropTypes.string,
    className: React.PropTypes.string,
    elements: React.PropTypes.node,
    none_message: React.PropTypes.string
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
          <span key="ttindicator" className="tooltip-indicator"></span>
        )];
      }
      headers.push((
        <th onClick={headerOnClick} className={headerClass} key={key}>
          <span dangerouslySetInnerHTML={{ __html: keyObj.label }}></span>
          <span className="sortable-indicator"></span>
          {tooltip}
        </th>
      ));
    }


    let className = `${this.props.table_key} table `;

    if (this.props.className) { className += this.props.className; }

    if (this.props.sortable) { className += ' table--sortable'; }

    let { elements } = this.props;
    let text;
    if (elements.length === 0) {
      if (this.props.store.isLoaded()) {
        text = this.props.none_message;
        if (typeof text === 'undefined' || text === null) { text = I18n.t(`${this.props.table_key}.none`); }
      } else {
        text = I18n.t(`${this.props.table_key}.none`);
      }
      elements = (
        <tr className="disabled">
          <td colSpan={headers.length + 1} className="text-center">
            <span>{text}</span>
          </td>
        </tr>
      );
    }

    return (
      <table className={className}>
        <thead>
          <tr>
            {headers}
            <th></th>
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
