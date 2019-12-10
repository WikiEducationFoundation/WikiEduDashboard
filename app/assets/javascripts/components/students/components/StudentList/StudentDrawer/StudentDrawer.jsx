import React from 'react';
import PropTypes from 'prop-types';

// Components
import RevisionRow from './RevisionRow';
import NoRevisionsRow from './NoRevisionsRow';
import FullHistoryRow from './FullHistoryRow';
import TrainingStatus from '@components/students/training_status.jsx';

export class StudentDrawer extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      selectedIndex: -1,
    };
  }

  shouldComponentUpdate(nextProps) {
    return !!(nextProps.isOpen || this.props.isOpen);
  }

  showDiff(index) {
    this.setState({ selectedIndex: index });
  }

  render() {
    const { isOpen, revisions = [], student, trainingModules = [] } = this.props;
    if (!isOpen) return <tr />;

    const rows = revisions.map((revision, index) => (
      <RevisionRow revision={revision} index={index} />
    ));

    if (rows.length === 0) rows.push(<NoRevisionsRow student={student} />);
    rows.push(<FullHistoryRow student={student} />);

    return (
      <tr className="drawer">
        <td colSpan="7">
          <TrainingStatus trainingModules={trainingModules} />
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
            <tbody>{rows}</tbody>
          </table>
        </td>
      </tr>
    );
  }
}

StudentDrawer.propTypes = {
  course: PropTypes.object,
  student: PropTypes.object,
  isOpen: PropTypes.bool,
  revisions: PropTypes.array,
  trainingModules: PropTypes.array,
  wikidataLabels: PropTypes.object
};

export default StudentDrawer;
