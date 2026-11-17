import React, { useState } from 'react';
import PropTypes from 'prop-types';
import { useSelector } from 'react-redux';
import useCampaignDownloadModal from '../../hooks/useCampaignDownloadModal.js';

// The campaign reports leave private courses out. Admins and organizers
// (campaign.editable) can ask for the variant that includes them, which the
// server caches under its own name and serves only to them.
const withPrivateCourses = ({ id, href, ...option }) => ({
  ...option,
  id: `${id}-with-private-courses`,
  href: `${href}${href.includes('?') ? '&' : '?'}include_private=true`
});

const CampaignStatsDownloadModal = ({ campaign_slug, campaign: campaignProp }) => {
  const campaignFromStore = useSelector(state => state.campaign);
  const campaign = campaignProp || campaignFromStore;
  const campaignTitle = campaign?.title || campaign_slug;
  const [includePrivate, setIncludePrivate] = useState(false);

  const {
    show,
    openModal,
    closeModal,
    handleDownload,
    userSignedIn
  } = useCampaignDownloadModal({ campaignTitle });

  const publicOptions = [
    {
      id: `${campaign_slug}-courses`,
      href: `/campaigns/${campaign_slug}/courses.csv`,
      dataLabel: I18n.t('campaign.data_courses'),
      info: I18n.t('campaign.data_courses_info')
    },
    {
      id: `${campaign_slug}-articles`,
      href: `/campaigns/${campaign_slug}/articles_csv.csv`,
      dataLabel: I18n.t('campaign.data_articles'),
      info: I18n.t('campaign.data_articles_info')
    },
    {
      id: `${campaign_slug}-students`,
      href: `/campaigns/${campaign_slug}/students.csv`,
      dataLabel: I18n.t('campaign.data_editor_usernames'),
      info: I18n.t('campaign.data_editor_usernames_info')
    },
    {
      id: `${campaign_slug}-students-by-course`,
      href: `/campaigns/${campaign_slug}/students.csv?course=true`,
      dataLabel: I18n.t('campaign.data_editors_by_course'),
      info: I18n.t('campaign.data_editors_by_course_info')
    },
    {
      id: `${campaign_slug}-instructors-by-course`,
      href: `/campaigns/${campaign_slug}/instructors.csv?course=true`,
      dataLabel: I18n.t('campaign.data_instructors'),
      info: I18n.t('campaign.data_instructors_info')
    },
    {
      id: `${campaign_slug}-wikidata`,
      href: `/campaigns/${campaign_slug}/wikidata.csv`,
      dataLabel: I18n.t('campaign.data_wikidata'),
      info: I18n.t('campaign.data_wikidata_info')
    }
  ];
  const canIncludePrivate = Boolean(campaign?.editable);
  const downloadOptions = canIncludePrivate && includePrivate
    ? publicOptions.map(withPrivateCourses)
    : publicOptions;

  if (!show) {
    return (
      <button onClick={openModal} className="button">{I18n.t('courses.download_stats_data')}</button>
    );
  }

  return (
    <div className="basic-modal course-stats-download-modal">
      <button onClick={closeModal} className="pull-right article-viewer-button icon-close" />
      <h2>{I18n.t('campaign.data_download_info')}</h2>
      {canIncludePrivate && (
        <label className="campaign-private-courses-toggle">
          <input
            type="checkbox"
            checked={includePrivate}
            onChange={e => setIncludePrivate(e.target.checked)}
          />
          {' '}
          {I18n.t('campaign.data_include_private_courses')}
        </label>
      )}
      <hr />
      {downloadOptions.map((option, index) => (
        <React.Fragment key={option.id}>
          {index > 0 && <hr />}
          <p>
            {userSignedIn ? (
              <button
                type="button"
                onClick={e => handleDownload(option, e)}
                className="button right"
              >
                {option.dataLabel}
              </button>
            ) : (
              <a
                href={option.href}
                className="button right"
              >
                {option.dataLabel}
              </a>
            )}
            {option.info}
          </p>
        </React.Fragment>
      ))}
    </div>
  );
};

CampaignStatsDownloadModal.propTypes = {
  campaign_slug: PropTypes.string.isRequired,
  campaign: PropTypes.shape({
    title: PropTypes.string
  })
};

export default CampaignStatsDownloadModal;
