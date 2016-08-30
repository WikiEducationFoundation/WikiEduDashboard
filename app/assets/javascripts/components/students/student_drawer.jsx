import React from 'react';
import Expandable from '../high_order/expandable.jsx';
import RevisionStore from '../../stores/revision_store.js';
import TrainingStatus from './training_status.jsx';

const getRevisions = studentId => RevisionStore.getFiltered({ user_id: studentId });

const StudentDrawer = React.createClass({
  displayName: 'StudentDrawer',

  propTypes: {
    student_id: React.PropTypes.number,
    is_open: React.PropTypes.bool
  },

  mixins: [RevisionStore.mixin],

  getInitialState() {
    return { revisions: getRevisions(this.props.student_id) };
  },

  getKey() {
    return `drawer_${this.props.student_id}`;
  },

  storeDidChange() {
    return this.setState({ revisions: getRevisions(this.props.student_id) });
  },

  render() {
    if (!this.props.is_open) { return <tr></tr>; }

    let revisions = (this.state.revisions || []).map((rev) => {
      let details = I18n.t('users.revision_characters_and_views', { characters: rev.characters, views: rev.views });
      return (
        <tr key={rev.id}>
          <td>
            <p className="name">
              <a href={rev.article.url} target="_blank">{rev.article.title}</a>
              <br />
              <small className="tablet-only-ib">{details}</small>
            </p>
          </td>
          <td className="desktop-only-tc date">{moment(rev.date).format('YYYY-MM-DD   h:mm A')}</td>
          <td className="desktop-only-tc">{rev.characters}</td>
          <td className="desktop-only-tc">{rev.views}</td>
          <td className="desktop-only-tc">
            <a href={rev.url} target="_blank">{I18n.t('revisions.diff')}</a>
          </td>
        </tr>
      );
    });

    if (this.props.is_open && revisions.length === 0) {
      revisions = (
        <tr>
          <td colSpan="7" className="text-center">
            <p>{I18n.t('users.no_revisions')}</p>
          </td>
        </tr>
      );
    }

    let className = 'drawer';
    className += !this.props.is_open ? ' closed' : '';

    return (
        <tr className={className}>
          <td colSpan="7">
            <TrainingStatus />
            <div>
              <table className="table">
                <thead>
                  <tr>
                    <th>{I18n.t('users.contributions')}</th>
                    <th className="desktop-only-tc">{I18n.t('metrics.date_time')}</th>
                    <th className="desktop-only-tc">{I18n.t('metrics.char_added')}</th>
                    <th className="desktop-only-tc">{I18n.t('metrics.view')}</th>
                    <th className="desktop-only-tc"></th>
                  </tr>
                </thead>
                <tbody>{revisions}</tbody>
              </table>
            </div>
          </td>
        </tr>
    );
  }
}
);

export default Expandable(StudentDrawer);
