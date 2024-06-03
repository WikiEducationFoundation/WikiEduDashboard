import React, { useState, useEffect } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import { fetchAllNewsContent, cacheNewsContentEdit, cancelNewsContentEditing } from '@actions/news_action';
import NewsPopoverContentDropdown from './news_popover_content_dropdown';
import TextAreaInput from '@components/common/text_area_input.jsx';
import Loading from '../../../common/loading';
import { formatDistanceToNowStrict } from 'date-fns';

// NewsPopoverContent component
const NewsPopoverContent = ({ createNews }) => {
  // Retrieve the news content list from the Redux store
  const newsContentList = useSelector(state => state.news.news_content_list);
  const dispatch = useDispatch();

  // State variables
  const [newsHoverId, setNewsHoverId] = useState(null); // Store the ID of the news item being hovered over
  const [confirmDeleteNewsId, setConfirmDeleteNewsId] = useState(false); // Store the ID of the news item to be deleted (for confirmation)
  const [editNewsId, setEditNewsId] = useState(null); // Store the ID of the news item being edited
  const [newsEditDropdown, setNewsEditDropdown] = useState(false); // Toggle the visibility of the edit dropdown
  const [newsCreatedTime, setNewsCreatedTime] = useState([]); // Store the creation time of each news item (for display purposes)
  const [loading, setLoading] = useState(true); // Track the loading state of the news content

  // Get the current user's admin status from the DOM
  const navRoot = document.getElementById('nav_root');
  const currentUserIsAdmin = navRoot.getAttribute('data-ifadmin');

  // Fetch all news content from the server when the component mounts
  useEffect(() => {
    const fetch = async () => {
      const status = await dispatch(fetchAllNewsContent());
      setLoading(!status);
    };
    fetch();
  }, []);

  // Update the newsCreatedTime array whenever the newsContentList changes
  useEffect(() => {
    newsContentList.forEach((news, index) => {
      updateNewsCreationTime(index, formatRelativeTime(news.created_at));
    });
  }, [newsContentList]);

  // Set the ID of the news item to be edited
  const setNewsIdToBeEdited = (newsId) => {
    setEditNewsId(newsId);
  };

  // Cancel the editing of a news item which was set to be edited
  const cancelNewsIdToBeEdited = () => {
    dispatch(cancelNewsContentEditing());
    setEditNewsId(null);
  };

  // Save the edited news content
  const saveEditedNews = () => {
    setEditNewsId(null);
  };

  // Temporarily cache the current edited news content in the Redux store
  const cacheEditedNewsContent = (_valueKey, value) => {
    dispatch(cacheNewsContentEdit({ content: value, id: editNewsId }));
  };

  // Set the ID of the news item being hovered over
  const setNewsHover = (value) => {
    setNewsHoverId((prevId) => {
      if (prevId !== value && newsEditDropdown) {
        setNewsEditDropdown(false);
      }
      return value;
    });
  };

  // Format the given date string as a relative time (e.g., "2 hours ago")
  const formatRelativeTime = (dateString) => {
    const date = new Date(dateString);
    return formatDistanceToNowStrict(date, { addSuffix: true });
  };

  // Store news creation time to prevent real-time updates, which could make it appear like a timer
  const updateNewsCreationTime = (index, newsCreationTime) => {
    setNewsCreatedTime((prevTimes) => {
      const newsTimeItems = [...prevTimes];
      newsTimeItems[index] = newsCreationTime;
      return newsTimeItems;
    });
  };

  // If the news content is still loading, show a loading spinner
  if (loading) {
    return <Loading />;
  }

  // If there are no news items and createNews prop is falsy, show a message
  if (!newsContentList.length && !createNews) {
    return (
      <div className="no-news">
        <div className="icon-wrapper">
          <span className="icon icon-notifications-grey_news"/>
        </div>
        <p>{I18n.t('news.no_updates.message')}</p>
        <p>{I18n.t('news.no_updates.check_later')}</p>
        <hr />
      </div>
    );
  }

  // Map over the newsContentList to render each news item
  const newsContent = newsContentList.map((news, index) => {
    const isCurrentlyEditedNews = editNewsId === news.id;
    const isHovered = newsHoverId === news.id;
    const confirmDelete = confirmDeleteNewsId === news.id;
    // Opaque text area input when admin selects delete news
    const opaqueTextAreaInput = confirmDelete ? 'disable-text-area-input' : '';
    // Opaque news creation time when admin selects delete news
    const opaqueNewsCreationTime = confirmDelete ? 'disable-text-area-input' : '';

    // Render the NewsPopoverContentOptions component with relevant props
    const newsDropDownOptions = (
      <NewsPopoverContentDropdown
        setNewsIdToBeEdited={setNewsIdToBeEdited}
        newsId={news.id}
        isCurrentlyEditedNews={isCurrentlyEditedNews}
        saveEditedNews={saveEditedNews}
        confirmDeleteNewsId={confirmDeleteNewsId}
        setConfirmDeleteNewsId={setConfirmDeleteNewsId}
        cancelNewsIdToBeEdited={cancelNewsIdToBeEdited}
      />
    );

    return (
      <div className="news-section" key={news.id}>
        <div
          className={`news-content ${newsHoverId ? 'hovered' : ''}`}
          onMouseEnter={() => setNewsHover(news.id)}
          onMouseLeave={() => setNewsHover(null)}
        >
          <div className={`module__data news-text-area ${opaqueTextAreaInput}`}>
            {/* Render the TextAreaInput component for editing news content */}
            <TextAreaInput
              id={`${news.id}`}
              editable={isCurrentlyEditedNews}
              onChange={cacheEditedNewsContent}
              placeholder={I18n.t('news.text_area_input.placeholder')}
              value={news.content}
              value_key="news"
              markdown={true}
              autoExpand={true}
            />
          </div>
          {/* Show the edit dropdown if the user is an admin and hovering over the news item */}
          {isHovered && currentUserIsAdmin === 'true' ? (
            <div className="dot-circle">
              <span className="icon-edit_news news-edit" onClick={() => setNewsEditDropdown(value => !value)}>
                <span className={`${newsEditDropdown ? 'dot-icon-circle dot-clicked' : ''}`} />
                {newsEditDropdown && newsDropDownOptions}
              </span>
            </div>
          ) : (
            <span />
          )}
          {/* Show the creation time of the news item if it's not being edited */}
          {!isCurrentlyEditedNews ? <p className={opaqueNewsCreationTime}>{newsCreatedTime[index]}</p> : <span />}
        </div>
        {/* Show a confirmation message if the user wants to delete the news item */}
        {confirmDelete && (<h1>{I18n.t('news.delete_confirmation.title')}<br /> {I18n.t('news.delete_confirmation.confirmation')}</h1>)}
        <hr />
      </div>
    );
  });

  // Reverse the order of news items before rendering
  return newsContent.reverse();
};

export default NewsPopoverContent;
