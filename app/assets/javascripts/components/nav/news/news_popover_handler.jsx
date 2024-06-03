import React, { useState } from 'react';
import { useDispatch } from 'react-redux';
import { resetCreateNewsState } from '@actions/news_action';
import Notifications from './news_notification/notification';
import CreateNewsPopover from './create_news/create_news_popover';
import NewsPopoverHeader from './news_header/news_popover_header';
import NewsPopoverContent from './news_content/news_popover_content';
import NewsPopoverFooter from './news_footer/news_popover_footer';

// The NewsPopoverHandler component is responsible for rendering the news popover content
const NewsPopoverHandler = () => {
  // State to track whether the create news popover should be shown or not
  const [createNews, setCreateNews] = useState(false);
  const dispatch = useDispatch();

  // Render the NewsPopoverHeader, NewsPopoverContent, and NewsPopoverFooter components
  const newsHeader = <NewsPopoverHeader setCreateNews={setCreateNews} createNews={createNews} />;
  const newsContent = <NewsPopoverContent createNews={createNews} />;
  const newsFooter = <NewsPopoverFooter />;

  // Reset the create news state in redux store if the create news popover is not shown
  if (!createNews) {
    dispatch(resetCreateNewsState());
  }

  return (
    <>
      <div className="pop__container pop__container--news">
        <div className="pop pop--news open">
          <div className="pop__padded-content news--content padded-content--header">
            {newsHeader}
          </div>
          <div className="pop__padded-content news--content news-container">
            <Notifications />
            {/* Conditionally render the CreateNewsPopover component if createNews is true */}
            {createNews && <CreateNewsPopover setCreateNews={setCreateNews} />}
            {newsContent}
          </div>
          <div className="pop__padded-content news--content padded-content__footer">
            {newsFooter}
          </div>
        </div>
      </div>
    </>
  );
};

export default NewsPopoverHandler;
