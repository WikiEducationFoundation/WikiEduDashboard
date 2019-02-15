import React from 'react';
import PropTypes from 'prop-types';
import moment from 'moment';
import DiffViewer from './diff_viewer.jsx';
import CourseUtils from '../../utils/course_utils.js';
import createReactClass from 'create-react-class';

const Revision = createReactClass({
  displayName: 'Revision',

  propTypes: {
    revision: PropTypes.object,
    index: PropTypes.number,
    wikidataLabel: PropTypes.string,
    course: PropTypes.object,
    setSelectedIndex: PropTypes.func,
    lastIndex: PropTypes.number,
    selectedIndex: PropTypes.number
  },

  render() {
    const ratingClass = `rating ${this.props.revision.rating}`;
    const ratingMobileClass = `${ratingClass} tablet-only`;
    const formattedTitle = CourseUtils.formattedArticleTitle({
      title: this.props.revision.title,
      project: this.props.revision.wiki.project,
      language: this.props.revision.wiki.language
    }, this.props.course.home_wiki, this.props.wikidataLabel);

    return (
      <tr className="revision">
        <td className="tooltip-trigger desktop-only-tc">
          <p className="rating_num hidden">{this.props.revision.rating_num}</p>
          <div className={ratingClass}><p>{this.props.revision.pretty_rating || '-'}</p></div>
          <div className="tooltip dark">
            <p>{I18n.t(`articles.rating_docs.${this.props.revision.rating || '?'}`, { class: this.props.revision.rating || '' })}</p>
          </div>
        </td>
        <td>
          <div className={ratingMobileClass}><p>{this.props.revision.pretty_rating || '-'}</p></div>
          <a href={this.props.revision.article_url} target="_blank" className="inline">
            <p className="title">{formattedTitle}</p>
          </a>
        </td>
        <td className="desktop-only-tc">{this.props.revision.revisor}</td>
        <td className="desktop-only-tc">{this.props.revision.characters}</td>
        <td className="desktop-only-tc date">
          <a href={this.props.revision.url}>{moment(this.props.revision.date).format('YYYY-MM-DD   h:mm A')}</a>
        </td>
        <td>
          <DiffViewer
            index={this.props.index}
            revision={this.props.revision}
            editors={[this.props.revision.revisor]}
            articleTitle={this.props.revision.title}
            setSelectedIndex={this.props.setSelectedIndex}
            lastIndex={this.props.lastIndex}
            selectedIndex={this.props.selectedIndex}
          />
        </td>
      </tr>
    );
  },
});

export default Revision;
