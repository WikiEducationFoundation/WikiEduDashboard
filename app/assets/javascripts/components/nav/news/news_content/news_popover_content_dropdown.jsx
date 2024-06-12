import React from 'react';
import CancelEditNews from './options/cancel_edit_news';
import CancelDeleteNews from './options/cancel_delete_news';
import EditNews from './options/edit_news';
import DeleteNews from './options/delete_news';
import UpdateNews from './options/update_news';
import ConfirmDeleteNews from './options/confirm_delete_news';

// This component renders different options for editing, deleting, or updating a news item
const NewsPopoverContentDropdown = ({
  setNewsIdToBeEdited,
  newsId,
  isCurrentlyEditedNews,
  saveEditedNews,
  confirmDeleteNewsId,
  setConfirmDeleteNewsId,
  cancelNewsIdToBeEdited,
}) => {
  let firstOptions;
  let secondOptions;

  // Determine the options to display based on the component's state
  switch (true) {
    case confirmDeleteNewsId === newsId:
      // If the current news item is being confirmed for deletion
      firstOptions = <ConfirmDeleteNews newsId={newsId} />; // Render the "Confirm Delete" option
      secondOptions = <CancelDeleteNews setConfirmDeleteNews={setConfirmDeleteNewsId} />; // Render the "Cancel Delete" option
      break;
    case isCurrentlyEditedNews:
      // If the current news item is being edited
      firstOptions = <UpdateNews saveEditedNews={saveEditedNews} newsId={newsId} />; // Render the "Update" option
      secondOptions = <CancelEditNews cancelNewsIdToBeEdited={cancelNewsIdToBeEdited} />; // Render the "Cancel Edit" option
      break;
    default:
      // If none of the above cases match
      firstOptions = <DeleteNews setConfirmDeleteNewsId={setConfirmDeleteNewsId} newsId={newsId} />; // Render the "Delete" option
      secondOptions = <EditNews setNewsIdToBeEdited={setNewsIdToBeEdited} newsId={newsId} />; // Render the "Edit" option
  }

  return (
    <div onClick={(e) => { e.stopPropagation(); }} className="pop__container news-dropdown-options">
      <div className="pop pop--news open">
        <div className="news-dropdown-options-display">
          {firstOptions} {/* Render the first set of options */}
          <hr className="news-hr" /> {/* Horizontal rule separator */}
          {secondOptions} {/* Render the second set of options */}
        </div>
      </div>
    </div>
  );
};

export default NewsPopoverContentDropdown;
