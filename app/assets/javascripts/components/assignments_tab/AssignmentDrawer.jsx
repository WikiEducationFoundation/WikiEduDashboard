import React, { useEffect } from 'react';
import PropTypes from 'prop-types';
import Loading from '@components/common/loading.jsx';
import AssignmentRoster from './AssignmentRoster';

const COLUMNS = 7;

// The open row's drawer: that assignment's students and statuses. Rows are
// fetched the first time the drawer opens and kept by the list, so reopening
// it is instant.
const AssignmentDrawer = ({ item, itemData, loadItem, tabPath }) => {
  useEffect(() => { if (!itemData) { loadItem(item.key); } }, [item.key]);

  let content;
  if (itemData?.failed) {
    content = <p role="alert">{I18n.t('system_stats.errors.fetch_failed')}</p>;
  } else if (!itemData) {
    content = <Loading />;
  } else {
    const cellsByUser = Object.fromEntries(itemData.rows.map(cell => [cell.user_id, cell]));
    content = (
      <AssignmentRoster
        item={item} students={itemData.students} cellsByUser={cellsByUser}
        itemPath={`${tabPath}/${item.key}`}
      />
    );
  }

  return (
    <tr className="drawer" id={`assignment-drawer-${item.key}`}>
      <td colSpan={COLUMNS}>{content}</td>
    </tr>
  );
};

AssignmentDrawer.propTypes = {
  item: PropTypes.object.isRequired,
  itemData: PropTypes.object,
  loadItem: PropTypes.func.isRequired,
  tabPath: PropTypes.string.isRequired,
};

export default AssignmentDrawer;
