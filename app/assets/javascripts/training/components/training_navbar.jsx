import React from 'react';
import GetHelpButton from '../../components/common/get_help_button.jsx';

const TrainingNavbar = ({ course, currentUser }) => {
  let getHelp;
  if (Features.enableGetHelpButton) {
    getHelp = (
      <GetHelpButton currentUser={currentUser} course={course} key="get_help" />
    );
  }

  return (
    <div className="container">
      <nav>
        {getHelp}
      </nav>
    </div>
  );
};

export default TrainingNavbar;
