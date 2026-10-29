import { useState, useEffect } from 'react';
import { useDispatch } from 'react-redux';
import { startDownload } from '../actions/download_actions.js';
import { addNotification } from '../actions/notification_actions.js';

const useDownloadModal = ({
  title,
  campaignTitle,
  notificationMessage = I18n.t('campaign.data_download_generating')
} = {}) => {
  const dispatch = useDispatch();
  const [show, setShow] = useState(false);
  const userSignedIn = Boolean(typeof Features !== 'undefined' && Features.user_signed_in);
  const modalTitle = title || campaignTitle;

  useEffect(() => {
    if (!show) { return; }

    const handleEscape = (event) => {
      if (event.key === 'Escape') { setShow(false); }
    };

    document.addEventListener('keydown', handleEscape);
    return () => document.removeEventListener('keydown', handleEscape);
  }, [show]);

  const handleDownload = (option, event) => {
    if (event) {
      event.preventDefault();
    }
    dispatch(startDownload({
      ...option,
      label: `${modalTitle} — ${option.dataLabel}`,
      onGenerating: () => {
        dispatch(addNotification({
          message: notificationMessage,
          closable: true,
          type: 'success'
        }));
      }
    }));
    setShow(false);
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };

  return {
    show,
    setShow,
    openModal: () => setShow(true),
    closeModal: () => setShow(false),
    handleDownload,
    userSignedIn
  };
};

export default useDownloadModal;

