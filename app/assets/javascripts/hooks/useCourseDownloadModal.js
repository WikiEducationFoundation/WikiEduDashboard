import useDownloadModal from './useDownloadModal.js';

const useCourseDownloadModal = ({ courseTitle } = {}) => {
  return useDownloadModal({
    title: courseTitle,
    notificationMessage: I18n.t('courses.data_download_generating', {
      defaultValue: I18n.t('campaign.data_download_generating')
    })
  });
};

export default useCourseDownloadModal;
