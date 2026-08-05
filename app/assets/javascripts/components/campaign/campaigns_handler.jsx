import React from 'react';
import { Route, Routes } from 'react-router-dom';
import Campaign from '../campaign/campaign.jsx';
import CampaignList from '../campaign/campaign_list.jsx';
import CampaignRow from './campaign_row';
import Notifications from '../common/notifications.jsx';

const CampaignsHandler = () => {
  const keys = {
    title: {
      label: I18n.t('campaign.campaigns'),
      desktop_only: false,
    },
    course_count: {
      label: I18n.t(`${Features.default_course_string_prefix}.courses`),
      desktop_only: false,
    },
    new_article_count: {
      label: I18n.t('metrics.articles_created'),
      desktop_only: false,
    },
    article_count: {
      label: I18n.t('metrics.articles_edited'),
      desktop_only: false,
    },
    word_count: {
      label: I18n.t('metrics.word_count'),
      desktop_only: false,
      info_key: 'courses.word_count_doc',
    },
    references_count: {
      label: I18n.t('metrics.references_count'),
      desktop_only: false,
      info_key: 'metrics.references_doc',
    },
    view_sum: {
      label: I18n.t('metrics.view'),
      desktop_only: false,
      info_key: 'courses.view_doc',
    },
    user_count: {
      label: I18n.t('users.editors'),
      desktop_only: false,
    },
  };

  if (!Features.wikiEd) {
    keys.creation_date = {
      label: I18n.t('courses.creation_date'),
      desktop_only: false,
    };
  }

  keys.export = {
    label: I18n.t('campaign.export'),
    desktop_only: false,
    sortable: false,
  };

  return (
    <>
      <Notifications />
      <Routes>
        <Route index element={<CampaignList showSearch={true} showStatistics={true} RowElement={CampaignRow} keys={keys}/>}/>
        <Route path=":campaign_slug/*" element={<Campaign />} />
      </Routes>
    </>
  );
};

export default CampaignsHandler;
