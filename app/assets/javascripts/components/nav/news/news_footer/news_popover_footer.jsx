import React from 'react';

// Utility function to determine the feature-specific values
const getFeatureValues = (isWikiEd) => {
  if (isWikiEd) {
    return {
      linkText: I18n.t('news.footer.wiki_education_dashboard.link_text'),
      linkUrl: 'https://wikiedu.org/blog/',
      footerText: I18n.t('news.footer.wiki_education_dashboard.footer_text'),
    };
  }
    return {
      linkText: I18n.t('news.footer.P&E_dashboard.link_text'),
      linkUrl: 'https://meta.wikimedia.org/wiki/Programs_%26_Events_Dashboard#News_and_recent_changes',
      footerText: I18n.t('news.footer.P&E_dashboard.footer_text'),
    };
};

// The NewsPopoverFooter component renders the footer section of the news popover
// It displays a link to the blog or news page based on the current feature (wikiEd or Wikimedia)
const NewsPopoverFooter = () => {
  // Determine the feature-specific values based on the current feature
  const { linkText, linkUrl, footerText } = getFeatureValues(Features.wikiEd);

  return (
    <nav aria-label="News footer links">
      <div className="news-footer">
        <p>{footerText}</p>
        <div className="tooltip-trigger">
          <p className="news-footer__link">
            {/* Render a link to the blog or news page with the appropriate URL */}
            <a href={linkUrl} target="_blank" rel="noopener noreferrer" aria-label={linkText}>
              <span className="news-link link"> </span>
            </a>
          </p>
          <span className="tooltip tooltip--news tooltip--small">
            <p>{linkText}</p>
          </span>
        </div>
      </div>
    </nav>
  );
};

export default NewsPopoverFooter;
