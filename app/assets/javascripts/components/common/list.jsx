import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import Loading from './loading.jsx';
import UIActions from '../../actions/ui_actions.js';

const List = createReactClass({

  propTypes: {
    store: PropTypes.object,
    keys: PropTypes.object,
    sortable: PropTypes.bool,
    table_key: PropTypes.string,
    className: PropTypes.string,
    elements: PropTypes.node,
    none_message: PropTypes.string,
    sortBy: PropTypes.func,
    stickyHeader: PropTypes.bool
  },

  getInitialState() {
    return { fixHeader: false };
  },

  componentDidMount() {
    if (this.props.stickyHeader) {
      return window.addEventListener('scroll', this._UpdateTableHeaders);
  }},

  componentWillUnmount() {
    if (this.props.stickyHeader) {
      return window.removeEventListener('scroll', this._UpdateTableHeaders);
    }
  },

  _UpdateTableHeaders() {
    if (this.props.stickyHeader) {
      const { fixHeader } = this.state;
      const persistAreaElements = document.getElementsByClassName('persist-area');
      for (let i = 0; i < persistAreaElements.length; i++) {
        const persistAreaElement = persistAreaElements[i];
        if (fixHeader) {
          const floatingHeaderRow = persistAreaElements[i].getElementsByClassName('floatingHeader')[0];
          const style = window.getComputedStyle(persistAreaElement);
          const width = style.getPropertyValue('width');
          floatingHeaderRow.style.width = width;
        }
        const offset = persistAreaElement.offsetTop;
        const scrollTop = document.documentElement.scrollTop || document.body.scrollTop;
        if (!fixHeader && scrollTop >= offset && scrollTop < offset + persistAreaElement.clientHeight) {
          this.setState({ fixHeader: true });
        }
        if (fixHeader && scrollTop >= offset && scrollTop > offset + persistAreaElement.clientHeight) {
           this.setState({ fixHeader: false });
        }
        if (fixHeader && scrollTop < offset) {
           this.setState({ fixHeader: false });
        }
      }
    }
  },

  render() {
    const { store, keys, sortable, table_key, className, none_message, sortBy, loading, stickyHeader } = this.props;
    let { elements } = this.props;
    const sorting = store && store.getSorting();
    const sortClass = (sorting && sorting.asc) ? 'asc' : 'desc';
    const headers = [];
    const iterable = Object.keys(keys);

    const sortByFunction = (tableKey, key) => {
      if (sortBy) {
        return () => {
          sortBy(key);
        };
      }
      return UIActions.sort.bind(null, tableKey, key);
    };

    for (let i = 0; i < iterable.length; i++) {
      const key = iterable[i];
      const keyObj = keys[key];
      let headerOnClick;
      let headerClass = (sorting && sorting.key) === key ? sortClass : '';
      let tooltip;
      headerClass += keyObj.desktop_only ? ' desktop-only-tc' : '';
      if ((sortable !== false) && (keyObj.sortable !== false)) {
        headerClass += ' sortable';
        headerOnClick = sortByFunction(table_key, key);
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

    // eslint-disable-next-line
    let defaultClassName = `${table_key} table `;

    if (className) { defaultClassName += className; }

    if (sortable) { defaultClassName += ' table--sortable'; }

    // Handle the case of no elements:
    // Show a none message if data is already loaded, or
    // show the Loading spinner if data is not yet loaded.
    if (elements.length === 0) {
      let emptyMessage;
      if (store && store.isLoaded() || !loading) {
        // eslint-disable-next-line
        let noneMessage = none_message;
        if (typeof noneMessage === 'undefined' || noneMessage === null) {
          // eslint-disable-next-line
          noneMessage = I18n.t(`${table_key}.none`);
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
    let fixedHeader;
    let fixedArea;
    if (stickyHeader) {
      fixedArea = "persist-area";
      const fixHeader = this.state.fixHeader === true ? 'floatingHeader' : '';
      fixedHeader = "persist-header";
      fixedHeader += ` ${fixHeader}`;
    }
    return (
      <div className={fixedArea}>
        <table className={defaultClassName}>
          <thead className={fixedHeader}>
            <tr>
              {headers}
              <th />
            </tr>
          </thead>
          <tbody>
            {elements}
          </tbody>
        </table>
      </div>
    );
  }
});

export default List;
