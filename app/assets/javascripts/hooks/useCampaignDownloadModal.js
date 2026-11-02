import { useState, useEffect } from 'react';
import { useDispatch } from 'react-redux';
import { startDownload } from '../actions/download_actions.js';
import { addNotification } from '../actions/notification_actions.js';

const useCampaignDownloadModal = ({ campaignTitle }) => {
  const dispatch = useDispatch();
  const [show, setShow] = useState(false);
  const userSignedIn = Boolean(typeof Features !== 'undefined' && Features.user_signed_in);

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
      label: `${campaignTitle} — ${option.dataLabel}`,
      onGenerating: () => {
        dispatch(addNotification({
          message: I18n.t('campaign.data_download_generating'),
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

export default useCampaignDownloadModal;
