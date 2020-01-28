import React from 'react';
import CampaignStats from './campaign_stats.jsx';
import CourseUtils from '../../utils/course_utils.js';

const REVISION_TIMEFRAME = 7;
const CampaignPrograms = (props) => {
  return (
    <div>
      <header className="main-page">
        <div className="container">
          <CampaignStats campaign={props.campaign} />
        </div>
      </header>
      <div className="container">
        <section id="courses">
          <div className="section-header">
            <h3>{I18n.t(`${props.campaign.course_string_prefix}.campaign_courses`, { title: props.campaign.title })}
            </h3>
            < div className="sort-select" >
              <select className="sorts" rel="courses">
                <option rel="asc" value="title">
                  {I18n.t('courses.title')}
                </option>
                <option rel="asc" value="school">
                  {I18n.t('courses.school')}
                </option>
                <option rel="desc" value="revisions">
                  {I18n.t('metrics.revisions')}
                </option>
                <option rel="desc" value="characters">
                  {I18n.t('metrics.word_count')}
                </option>
                <option rel="desc" value="average-words">
                  {I18n.t('metrics.word_count_average')}
                </option>
                <option rel="desc" value="references">
                  {I18n.t('metrics.references_count')}
                </option>
                <option rel="desc" value="views">
                  {I18n.t('views')}
                </option>
                <option rel="desc" value="students">
                  {I18n.t('users.editors')}
                </option>
                <option rel="desc" value="untrained">
                  {I18n.t('courses.untrained')}
                </option>
                <option rel="desc" value="creation-date">
                  {I18n.t('courses.creation_date')}
                </option>
              </select>
            </div>
          </div>
          <table className="table table--hoverable table--sortable">
            <thead>
              <tr>
                <th className="sort sortable asc" data-default-order="asc" data-sort="title">
                  {CourseUtils.i18n('courses', props.campaign.course_string_prefix)}
                  <span className="sortable-indicator" />
                </th>
                <th className="sort sortable" data-default-order="asc" data-sort="school" style={{ width: '200px' }}>
                  {CourseUtils.i18n('school_and_term', props.campaign.course_string_prefix)}
                  <span className="sortable-indicator" />
                  {/* if logic needed to be fixed */}
                </th>
                <th className="sort sortable" data-default-order="desc" data-sort="revisions" style={{ width: '165px' }}>
                  <div className="tooltip-trigger">
                    {I18n.t('metrics.revisions')}
                    <span className="sortable-indicator" />
                    <span className="tooltip-indicator" />
                    <div className="tooltip dark">
                      <p>{I18n.t('courses.revisions_doc', { timeframe: REVISION_TIMEFRAME })}</p>
                    </div>
                  </div>
                </th>
                <th className="sort sortable" data-default-order="desc" data-sort="characters" style={{ width: '172px' }}>
                  <div className="tooltip-trigger">
                    {I18n.t('metrics.word_count')}
                    <span className="sortable-indicator" />
                    <span className="tooltip-indicator" />
                    <div className="tooltip dark">
                      {/* <p>{CourseUtils.i18('word_count_doc')}</p> */}
                    </div>
                  </div>
                </th>
                <th className="sort sortable" data-default-order="desc" data-sort="references" style={{ width: '172px' }}>
                  <div className="tooltip-trigger">
                    {I18n.t('metrics.references_count')}
                    <span className="sortable-indicator" />
                    <span className="tooltip-indicator" />
                    <div className="tooltip dark">
                      <p>{I18n.t('metrics.references_doc')}</p>
                    </div>
                  </div>
                </th>
                <th className="sort sortable" data-default-order="desc" data-sort="views" style={{ width: '125px' }}>
                  <div className="tooltip-trigger">
                    {I18n.t('metrics.view')}
                    <span className="sortable-indicator" />
                    <span className="tooltip-indicator" />
                    <div className="tooltip dark">
                      <p>{I18n.t('courses.view_doc')}</p>
                    </div>
                  </div>
                </th>
                <th className="sort sortable" data-default-order="desc" data-sort="students" style={{ width: '200px' }}>
                  {I18n.t('users.editors')}
                  <span className="sortable-indicator" />
                </th>
                <th className="sort sortable" data-default-order="desc" data-sort="creation-date" style={{ width: '160px' }}>
                  {I18n.t('courses.creation_date')}
                  <span className="sortable-indicator" />
                </th>
                <th style={{ width: '160px' }}>
                  {I18n.t('courses.actions')}
                </th>
              </tr>
            </thead>
            <tbody className="list">
              <tr className data-link="/courses/QCA/Brisbane_QCA_" />
            </tbody>
          </table>
        </section>
      </div>
    </div>
  );
};

export default CampaignPrograms;

