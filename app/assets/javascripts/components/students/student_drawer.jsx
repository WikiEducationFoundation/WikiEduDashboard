import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import moment from 'moment';
import TrainingStatus from './training_status.jsx';
import DiffViewer from '../revisions/diff_viewer.jsx';
import CourseUtils from '../../utils/course_utils.js';

const StudentDrawer = createReactClass({
  displayName: 'StudentDrawer',

  propTypes: {
    course: PropTypes.object,
    student: PropTypes.object,
    isOpen: PropTypes.bool,
    revisions: PropTypes.array,
    trainingModules: PropTypes.array,
    wikidataLabels: PropTypes.object
  },

  getInitialState() {
    return {
      selectedIndex: -1,
    };
  },

  shouldComponentUpdate(nextProps) {
    if (nextProps.isOpen || this.props.isOpen) { return true; }
    return false;
  },

  showDiff(index) {
    this.setState({
      selectedIndex: index
    });
  },

  render() {
    if (!this.props.isOpen) { return <tr />; }

    const revisions = this.props.revisions || [];
    const revisionsRows = revisions.map((rev, index) => {
      const article = rev.article;
      const label = this.props.wikidataLabels[article.title];
      const formattedTitle = CourseUtils.formattedArticleTitle(article, this.props.course.home_wiki, label);
      const details = I18n.t('users.revision_characters_and_views', { characters: rev.characters, views: rev.views });
      return (
        <tr key={rev.id}>
          <td>
            <p className="name">
              <a href={rev.article.url} target="_blank">{formattedTitle}</a>
              <br />
              <small className="tablet-only-ib">{details}</small>
            </p>
          </td>
          <td className="desktop-only-tc date"><a href={rev.url} target="_blank">{moment(rev.date).format('YYYY-MM-DD   h:mm A')}</a></td>
          <td className="desktop-only-tc">{rev.characters}</td>
          <td className="desktop-only-tc">{rev.references_added}</td>
          <td className="desktop-only-tc">{rev.views}</td>
          <td className="desktop-only-tc">
            <DiffViewer
              revision={rev}
              index={index}
              editors={[this.props.student.username]}
              articleTitle={formattedTitle}
              setSelectedIndex={this.showDiff}
              lastIndex={this.props.revisions.length}
              selectedIndex={this.state.selectedIndex}
            />
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
                <th className="desktop-only-tc">{I18n.t('metrics.references_count')}</th>
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
