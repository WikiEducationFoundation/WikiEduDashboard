import React from 'react';
import PropTypes from 'prop-types';

// Components
import DiffViewer from '@components/revisions/diff_viewer.jsx';

// Helpers
import CourseUtils from '~/app/assets/javascripts/utils/course_utils';
import { formatWithTime } from '~/app/assets/javascripts/utils/date_utils';

export const RevisionRow = ({ course, index, revision, revisions, selectedIndex, student, wikidataLabels, showDiff }) => {
  const article = revision.article;
  const label = wikidataLabels[article.title];
  const formattedTitle = CourseUtils.formattedArticleTitle(article, course.home_wiki, label);
  const details = I18n.t('users.revision_characters_and_views', { characters: revision.characters, views: revision.views });
  const revisionDate = formatWithTime(revision.date);
  return (
    <tr key={revision.id}>
      <td>
        <p className="name">
          <a href={revision.article.url} target="_blank">{formattedTitle}</a>
          <br />
          <small className="tablet-only-ib">{details}</small>
        </p>
      </td>
      <td className="desktop-only-tc date"><a href={revision.url} target="_blank">{revisionDate}</a></td>
      <td className="desktop-only-tc">{revision.characters}</td>
      <td className="desktop-only-tc">{revision.references_added}</td>
      <td className="desktop-only-tc">{revision.views}</td>
      <td className="desktop-only-tc">
        <DiffViewer
          revision={revision}
          index={index}
          editors={[student.username]}
          articleTitle={formattedTitle}
          setSelectedIndex={showDiff}
          lastIndex={revisions.length}
          selectedIndex={selectedIndex}
        />
      </td>
    </tr>
  );
};

RevisionRow.propTypes = {
  revision: PropTypes.object.isRequired,
  index: PropTypes.number.isRequired
};

export default RevisionRow;
