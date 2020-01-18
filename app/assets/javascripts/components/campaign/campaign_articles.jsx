import React from 'react';
import CampaignStats from './campaign_stats.jsx';
import CourseUtils from '../../utils/course_utils.js';


const CampaignArticles = (props) => {
  return (
    <div>
      <div className="container">
        <section className="overview container">
          <CampaignStats campaign={props.campaign} />
        </section>
      </div>
      <div className="container">
        <section id="campaign-articles">
          <div className="section-header">
            <h3>{I18n.t('courses.campaign_articles', { title: props.campaign.title })}</h3>
            <div className="sort-select">
              <select className="sorts">
                <option rel="desc" value="title">
                  {I18n.t('articles.title')}
                </option>
                <option rel="desc" value="char_added">
                  {I18n.t('metrics.char_added')}
                </option>
                <option rel="desc" value="references">
                  {I18n.t('metrics.references_count')}
                </option>
                <option rel="desc" value="views">
                  {I18n.t('metrics.view')}
                </option>
                <option rel="desc" value="lang_project">
                  {I18n.t('articles.wiki')}
                </option>
                <option rel="desc" value="course_title">
                  {CourseUtils.i18n('courses', props.campaign.course_string_prefix)}
                </option>
              </select>
            </div>
          </div>
          <table className="table table--hoverable table--sortable">
            <thead>
              <tr>
                <th className="sort sortable asc" data-default-order="asc" data-sort="title">
                  {I18n.t('articles.title')}
                  <span className="sortable-indicator" />
                </th>
                <th className="sort sortable" data-default-order="desc" data-sort="char_added">
                  <div className="tooltip-trigger">
                    {I18n.t('metrics.char_added')}
                    <span className="sortable-indicator" />
                    <span className="tooltip-indicator" />
                    <div className="tooltip dark">
                      <p>{I18n.t('articles.character_doc')}</p>
                    </div>
                  </div>
                </th>
                <th className="sort sortable" data-default-order="desc" data-sort="references">
                  <div className="tooltip-trigger">
                    {I18n.t('metrics.references_count')}
                    <span className="sortable-indicator" />
                    <span className="tooltip-indicator" />
                    <div className="tooltip dark">
                      <p>{I18n.t('metrics.references_doc')}</p>
                    </div>
                  </div>
                </th>
                <th className="sort sortable" data-default-order="desc" data-sort="views">
                  <div className="tooltip-trigger">
                    {I18n.t('metrics.view')}
                    <span className="sortable-indicator" />
                    <span className="tooltip-indicator" />
                    <div className="tooltip dark">
                      <p>{I18n.t('articles.view_doc')}</p>
                    </div>
                  </div>
                </th>
                <th className="sort sortable" data-sort="lang_project">
                  {I18n.t('articles.wiki')}
                  <span className="sortable-indicator" />
                </th>
                <th className="sort sortable" data-sort="course_title">
                  {CourseUtils.i18n('courses', props.campaign.course_string_prefix)}
                  <span className="sortable-indicator" />
                </th>
              </tr>
            </thead>
            <tbody className="list">
              <tr />
            </tbody>
          </table>
        </section>
      </div>
    </div>
  );
};

export default CampaignArticles;
