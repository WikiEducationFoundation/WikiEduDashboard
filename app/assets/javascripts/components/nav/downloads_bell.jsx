import React, { useState } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import useOutsideClick from '../../hooks/useOutsideClick';
import { markDownloadsRead, removeDownload } from '../../actions/download_actions.js';

const statusLabel = (status) => {
  if (status === 'pending') { return I18n.t('downloads.generating'); }
  if (status === 'error') { return I18n.t('downloads.error'); }
  return I18n.t('downloads.ready');
};

const DownloadsBell = () => {
  const dispatch = useDispatch();
  const { items, unreadCount } = useSelector(state => state.downloads);
  const [isOpen, setIsOpen] = useState(false);

  const closePopover = () => setIsOpen(false);
  const containerRef = useOutsideClick(closePopover);

  const togglePopover = () => {
    setIsOpen(open => !open);
    if (!isOpen && unreadCount > 0) {
      dispatch(markDownloadsRead());
    }
  };

  return (
    <li ref={containerRef} aria-describedby="downloads-notification-message" className="notifications tooltip-trigger pop__container">
      <button type="button" className="icon icon-notifications_bell downloads-bell" onClick={togglePopover} aria-label={I18n.t('downloads.aria_label')}>
        {unreadCount > 0 ? (
          <span className="bubble red">
            <span id="downloads-notification-message" className="screen-reader">{I18n.t('downloads.new_downloads')}</span>
          </span>
        ) : (
          <span id="downloads-notification-message" className="screen-reader">{I18n.t('downloads.no_downloads')}</span>
        )}
      </button>
      <div className={`pop pop--downloads ${isOpen ? 'open' : ''}`}>
        <div className="pop__padded-content downloads-list">
          <h3>{I18n.t('downloads.title')}</h3>
          <hr />
          {items.length === 0 ? (
            <p className="downloads-list__empty">{I18n.t('downloads.none')}</p>
          ) : (
            items.map(item => (
              <div key={item.id} className={`downloads-list__item downloads-list__item--${item.status}`}>
                <span className="downloads-list__label">{item.label}</span>
                <span className="downloads-list__status">
                  {item.status === 'ready' ? (
                    <a href={item.downloadUrl} className="downloads-list__download-button">{I18n.t('downloads.download')}</a>
                  ) : (
                    statusLabel(item.status)
                  )}
                </span>
                <button
                  type="button"
                  onClick={() => dispatch(removeDownload(item.id))}
                  className="downloads-list__dismiss"
                  aria-label={I18n.t('downloads.dismiss')}
                >
                  <span aria-hidden="true">&times;</span>
                </button>
              </div>
            ))
          )}
        </div>
      </div>
    </li>
  );
};

export default DownloadsBell;
