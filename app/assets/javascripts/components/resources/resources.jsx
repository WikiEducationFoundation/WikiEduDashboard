
import React from 'react';
import { connect } from 'react-redux';
import _ from 'lodash';

import CourseLink from '../common/course_link.jsx';
import { getWeeksArray } from '../../selectors';
import TrainingModules from '../timeline/training_modules';

const Resources = ({ weeks }) => {
  const blocks = _.flatten(weeks.map(week => week.blocks));
  const modules = _.compact(_.flatten(blocks.map(block => block.training_modules)));
  return (
    <div id="resources">
      <div className="section-header">
        <h3>{I18n.t('resources.header')}</h3>
        <div id="training-modules">
          <TrainingModules block_modules={modules} trainingLibrarySlug="students" />
          <CourseLink to={'/training/students'} className="button dark pull-right">All student training modules</CourseLink>
        </div>
        <hr />
        <div id="handouts">
          <h4>Handouts</h4>
          <ul>
            {/* <li><CourseLink to={wizardUrl} className="button dark">Instructor orientation modules</CourseLink></li>
            <li><CourseLink to={wizardUrl} className="button dark">Student training modules</CourseLink></li> */}
          </ul>
        </div>
      </div>
    </div>
  );
};

const mapStateToProps = state => ({
  weeks: getWeeksArray(state)
});

export default connect(mapStateToProps)(Resources);
