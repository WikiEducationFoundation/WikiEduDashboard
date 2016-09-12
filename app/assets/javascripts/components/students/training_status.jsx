import React from 'react';

const TrainingStatus = React.createClass({
  displayName: 'TrainingStatus',

  propTypes: {
    trainingModules: React.PropTypes.array
  },

  fakeArray: [
    { module_name: 'Editing Medical Topics', completed: true, completion_date: '2016-09-12T18:30:35.000Z' },
    { module_name: 'Peer Review', completed: false, completion_date: null }
  ],

  render() {
    const moduleRows = this.fakeArray.map((trainingModule) => {
      let moduleStatus;
      if (trainingModule.completed) {
        moduleStatus = `Completed ${trainingModule.completion_date}`;
      } else {
        moduleStatus = 'Incomplete';
      }
      return (
        <tr key={trainingModule.id}>
          <td>{trainingModule.module_name}</td>
          <td>{moduleStatus}</td>
        </tr>
      );
    });

    return (
      <div>
        <table className="table" style={{ border: '15px solid black' }}>
          <thead>
            <tr>
              <th>{I18n.t('users.training_module_name')}</th>
              <th>{I18n.t('users.training_module_status')}</th>
            </tr>
          </thead>
          <tbody>
            {moduleRows}
          </tbody>
        </table>
      </div>
    );
  }
});

export default TrainingStatus;
