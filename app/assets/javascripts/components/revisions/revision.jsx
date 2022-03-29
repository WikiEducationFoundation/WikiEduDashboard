import React from 'react';
import PropTypes from 'prop-types';
import moment from 'moment';
import DiffViewer from './diff_viewer.jsx';
import CourseUtils from '../../utils/course_utils.js';

const Revision = ({ references, assessment, revision, index, wikidataLabel, course, setSelectedIndex, lastIndex, selectedIndex }) => {
  if (!assessment) {
    assessment = {};
  }
  const ratingClass = `rating ${assessment.rating || revision.rating}`;
  const ratingMobileClass = `${ratingClass} tablet-only`;
  const formattedTitle = CourseUtils.formattedArticleTitle({ title: revision.title, project: revision.wiki.project, language: revision.wiki.language }, course.home_wiki, wikidataLabel);
  const subtitle = wikidataLabel ? `(${CourseUtils.removeNamespace(revision.title)})` : '';
  const isWikipedia = revision.wiki.project === 'wikipedia';

  return (
    <tr className="revision">
      <td className="tooltip-trigger desktop-only-tc">
        {isWikipedia && <p className="rating_num hidden">{assessment.rating_num || revision.rating_num}</p>}
        {isWikipedia && <div className={ratingClass}><p>{assessment.pretty_rating || revision.pretty_rating || '-'}</p></div>}
        {isWikipedia && <div className="tooltip dark">
          <p>{I18n.t(`articles.rating_docs.${assessment.rating || assessment.rating || '?'}`, { class: assessment.rating || revision.rating || '' })}</p>
          {/* eslint-disable-next-line */}
        </div>}
      </td>
      <td>
        {isWikipedia && <div className={ratingMobileClass}><p>{assessment.pretty_rating || revision.pretty_rating || '-'}</p></div>}
        <a href={revision.article_url} target="_blank" className="inline"><p className="title">{formattedTitle}&nbsp;<small>{subtitle}</small></p></a>
      </td>
      <td className="desktop-only-tc">{revision.revisor}</td>
      <td className="desktop-only-tc">{revision.characters}</td>
      <td className="desktop-only-tc">{references || revision.references_added}</td>
      <td className="desktop-only-tc date"><a href={revision.url}>{moment(revision.date).format('YYYY-MM-DD   h:mm A')}</a></td>
      <td>
        <DiffViewer
          index={index}
          revision={revision}
          editors={[revision.revisor]}
          articleTitle={revision.title}
          setSelectedIndex={setSelectedIndex}
          lastIndex={lastIndex}
          selectedIndex={selectedIndex}
        />
      </td>
    </tr>
  );
};

Revision.propTypes = {
  revision: PropTypes.object,
  index: PropTypes.number,
  wikidataLabel: PropTypes.string,
  course: PropTypes.object,
  setSelectedIndex: PropTypes.func,
  lastIndex: PropTypes.number,
  selectedIndex: PropTypes.number
};

export default Revision;
