import React from 'react';

const NewsPopoverHeader = ({ setCreateNews, createNews }) => {
  // Get the nav root element from the DOM
  const navRoot = document.getElementById('nav_root');

  // Check if the current user is an admin based on the data-ifadmin attribute
  const currentUserIsAdmin = navRoot.getAttribute('data-ifadmin');

  // Set header title
  const headerTitle = Features.wikiEd ? I18n.t('news.header.wiki_education_dashboard_title') : I18n.t('news.header.P&E_dashboard_title');

  // Disable create news options if admin in currently creating news
  const disableCreateNews = createNews ? 'disable-news' : '';

  return (
    <React.Fragment>
      <div className="news-header">
        <p>{headerTitle}</p>
        {/* Render the "Add News" button only if the current user is an admin */}
        {currentUserIsAdmin === 'true' && (
          <div onClick={() => setCreateNews(true)} className="tooltip-trigger">
            <p className="news-header__add">
              {/* Render a plus icon with dynamic styles based on the createNews state */}
              <span className={`icon-plus-blue ${disableCreateNews}`}>
                {<span className="add" />}
              </span>
            </p>
            {!createNews && (
              <span className="tooltip tooltip--news tooltip--small">
                <p>{I18n.t('news.add_news')}</p>
              </span>
            )}
          </div>
        )}
      </div>
      <hr className="news-hr" />
    </React.Fragment>
  );
};

export default NewsPopoverHeader;

