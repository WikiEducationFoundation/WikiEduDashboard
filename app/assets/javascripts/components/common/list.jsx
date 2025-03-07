import React, { useState, useEffect } from 'react';
import PropTypes from 'prop-types';
import Loading from './loading.jsx';

const List = ({
  keys,
  sortable,
  table_key,
  className,
  none_message,
  elements,
  sortBy,
  loading,
  stickyHeader,
}) => {
  const [fixHeader, setFixHeader] = useState(false);

  const updateTableHeaders = () => {
    if (stickyHeader) {
      const persistAreaElements = document.getElementsByClassName('persist-area');
      for (let i = 0; i < persistAreaElements.length; i += 1) {
        const persistAreaElement = persistAreaElements[i];
        if (fixHeader) {
          const floatingHeaderRow = persistAreaElements[i].getElementsByClassName('floatingHeader')[0];
          if (floatingHeaderRow) {
            const style = window.getComputedStyle(persistAreaElement);
            const width = style.getPropertyValue('width');
            floatingHeaderRow.style.width = width;
          }
        }
        const offset = persistAreaElement.offsetTop;
        const scrollTop = document.documentElement.scrollTop || document.body.scrollTop;
        if (!fixHeader && scrollTop >= offset && scrollTop < offset + persistAreaElement.clientHeight) {
          setFixHeader(true);
        }
        if (fixHeader && scrollTop >= offset && scrollTop > offset + persistAreaElement.clientHeight) {
          setFixHeader(false);
        }
        if (fixHeader && scrollTop < offset) {
          setFixHeader(false);
        }
      }
    }
  };

  useEffect(() => {
    if (stickyHeader) {
      window.addEventListener('scroll', updateTableHeaders);
      return () => {
        window.removeEventListener('scroll', updateTableHeaders);
      };
    }
  }, [stickyHeader, fixHeader]);

  const headers = [];
  const iterable = Object.keys(keys);

  const sortByFunction = (key) => {
    if (!sortBy) { return; }
    return () => sortBy(key);
  };

  for (let i = 0; i < iterable.length; i += 1) {
    const key = iterable[i];
    const keyObj = keys[key];
    if (keyObj.hidden) {
      // even though the column is hidden, the user can still use it to sort from the dropdown
      // the reason we hide it is because the data here is already present in another column. For example,
      // the words added column also contains the average word count information so it is not necessary
      // for it to have its own column

      // eslint-disable-next-line no-continue
      continue;
    }
    let headerOnClick;
    let headerClass = key;
    let tooltip;
    headerClass += keyObj.desktop_only ? ' desktop-only-tc' : '';
    if ((sortable !== false) && (keyObj.sortable !== false)) {
      headerClass += ' sortable';
      headerOnClick = sortByFunction(key);
    }
    if (keyObj.info_key) {
      headerClass += ' tooltip-trigger';
      const options = keyObj.info_key_options ?? {};
      tooltip = [(
        <div key="tt" className="tooltip dark">
          <p>{I18n.t(keyObj.info_key, options)}</p>
        </div>
      ), (
        <span key="ttindicator" className="tooltip-indicator-list" />
      )];
    }
    const order = (keyObj.order) ? keyObj.order : '';
    headers.push((
      <th onClick={headerOnClick} className={`${headerClass} ${order}`} key={key}>
        <span dangerouslySetInnerHTML={{ __html: keyObj.label }} />
        <span className={`sortable-indicator-${order} ${order}`} />
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
    if (!loading) {
      let noneMessage = none_message;
      if (typeof noneMessage === 'undefined' || noneMessage === null) {
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
    fixedArea = 'persist-area';
    const fixheader = fixHeader === true ? 'floatingHeader' : '';
    fixedHeader = 'persist-header';
    fixedHeader += ` ${fixheader}`;
  }
  return (
    <div className={fixedArea}>
      <table className={defaultClassName}>
        <thead className={fixedHeader}>
          <tr>
            {headers}
          </tr>
        </thead>
        <tbody>
          {elements}
        </tbody>
      </table>
    </div>
  );
};

List.propTypes = {
  keys: PropTypes.object,
  sortable: PropTypes.bool,
  table_key: PropTypes.string,
  className: PropTypes.string,
  elements: PropTypes.node,
  none_message: PropTypes.string,
  sortBy: PropTypes.func,
  stickyHeader: PropTypes.bool,
};



export default List;
