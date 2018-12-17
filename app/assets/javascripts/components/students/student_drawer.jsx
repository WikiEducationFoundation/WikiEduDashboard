import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import moment from 'moment';
import TrainingStatus from './training_status.jsx';
import DiffViewer from '../revisions/diff_viewer.jsx';

const StudentDrawer = createReactClass({
  displayName: 'StudentDrawer',

  propTypes: {
    student: PropTypes.object,
    isOpen: PropTypes.bool,
    revisions: PropTypes.array,
    trainingModules: PropTypes.array
  },

  shouldComponentUpdate(nextProps) {
    if (nextProps.isOpen || this.props.isOpen) { return true; }
    return false;
  },

  render() {
    if (!this.props.isOpen) { return <tr />; }

    const revisionsRows = (this.props.revisions || []).map((rev) => {
      const details = I18n.t('users.revision_characters_and_views', { characters: rev.characters, views: rev.views });
      return (
        <tr key={rev.id}>
          <td>
            <p className="name">
              <a href={rev.article.url} target="_blank">{rev.article.title}</a>
              <br />
              <small className="tablet-only-ib">{details}</small>
            </p>
          </td>
          <td className="desktop-only-tc date"><a href={rev.url} target="_blank">{moment(rev.date).format('YYYY-MM-DD   h:mm A')}</a></td>
          <td className="desktop-only-tc">{rev.characters}</td>
          <td className="desktop-only-tc">{rev.views}</td>
          <td className="desktop-only-tc">
            <DiffViewer revision={rev} editors={[this.props.student]} />
          </td>
        </tr>
      );
    });

    if (revisionsRows.length === 0) {
      revisionsRows.push(
        <tr key={`${this.props.student.id}-no-revisions`}>
          <td colSpan="7" className="text-center">
            <p>{I18n.t('users.no_revisions')}</p>
          </td>
        </tr>
      );
    }

    revisionsRows.push(
      <tr key={`${this.props.student.id}-contribs`}>
        <td colSpan="7" className="text-center">
          <p><a href={this.props.student.contribution_url} target="_blank">{I18n.t('users.contributions_history_full')}</a></p>
        </td>
      </tr>
    );

    return (
      <tr className="drawer">
        <td colSpan="7">
          <TrainingStatus trainingModules={this.props.trainingModules || []} />
          <table className="table">
            <thead>
              <tr>
                <th>{I18n.t('users.contributions')}</th>
                <th className="desktop-only-tc">{I18n.t('metrics.date_time')}</th>
                <th className="desktop-only-tc">{I18n.t('metrics.char_added')}</th>
                <th className="desktop-only-tc">{I18n.t('metrics.view')}</th>
                <th className="desktop-only-tc" />
              </tr>
            </thead>
            <tbody>{revisionsRows}</tbody>
          </table>
        </td>
      </tr>
    );
  }
});

export default StudentDrawer;
