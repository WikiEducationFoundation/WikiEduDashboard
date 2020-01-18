import React from 'react';
import CampaignStats from './campaign_stats.jsx';
import CourseUtils from '../../utils/course_utils.js';

const CampaignEditors = (props) => {
  return (
    <div>
      <div className="container campaign_main">
        <section className="overview container">
          <CampaignStats campaign={props.campaign} />
        </section>
      </div>
      <div className="container">
        <section id="users">
          <div className="section-header">
            <h3>{CourseUtils.i18n('students', props.campaign.course_string_prefix)}</h3>
            <div className="sort-select">
              <select className="sorts" rel="users">
                <option rel="desc" value="username">
                  {I18n.t('users.username')}
                </option>
                <option rel="desc" value="revision-count">
                  {I18n.t('courses.edit_count')}
                </option>
                <option rel="desc" value="title">
                  {I18n.t(`${props.campaign.course_string_prefix}.course`)}
                </option>
              </select>
            </div>
          </div>
          <table className="table table--hoverable table--sortable">
            <thead>
              <tr>
                <th className="sort sortable asc" data-default-order="asc" data-sort="username">
                  {I18n.t('users.username')}
                  <span className="sortable-indicator" />
                </th>
                <th className="sort sortable" data-default-order="asc" data-sort="revision-count">
                  {I18n.t('courses.edit_count')}
                  <span className="sortable-indicator" />
                </th>
                <th className="sort sortable" data-default-order="asc" data-sort="title">
                  {I18n.t(`${props.campaign.course_string_prefix}.course`)}
                  <span className="sortable-indicator" />
                </th>
              </tr>
            </thead>
            <tbody className="list">
              <tr>
                <td className="username">
                  <a href="#" />
                </td>
              </tr>
            </tbody>
          </table>
        </section>
      </div>
    </div>
  );
};

export default CampaignEditors;
