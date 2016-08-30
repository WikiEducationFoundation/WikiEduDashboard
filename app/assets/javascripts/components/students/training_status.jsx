import React from 'react';

const TrainingStatus = React.createClass({
  displayName: 'TrainingStatus',

  propTypes: {
    trainingModules: React.PropTypes.array
  },

  fakeArray: [
    { module_name: 'Ohai', module_status: 'Kthxbai', id: 1 },
    { module_name: 'Ohai', module_status: 'Kthxbai', id: 2 },
    { module_name: 'Ohai', module_status: 'Kthxbai', id: 3 },
  ],

  render() {
    const moduleRows = this.fakeArray.map((trainingModule) => {
      return (
        <tr key={trainingModule.id}>
          <td>{trainingModule.module_name}</td>
          <td>{trainingModule.module_status}</td>
        </tr>
      );
    });

    return (
      <div>
        <table className="table" style={{border: '15px solid black'}}>
          <thead>
            <tr>
              <th>{I18n.t('users.training_module')}</th>
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
