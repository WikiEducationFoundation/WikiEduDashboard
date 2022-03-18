import React from 'react';
import PropTypes from 'prop-types';
import { Route, Switch } from 'react-router-dom';

import TrainingModuleHandler from './training_module_handler.jsx';
import TrainingSlideHandler from './training_slide_handler.jsx';

const TrainingApp = () => (
  <div>
    <Switch>
      <Route exact path="/training/:library_id/:module_id" >
        <TrainingModuleHandler />
      </Route>
      <Route exact path="/training/:library_id/:module_id/:slide_id" >
        <TrainingSlideHandler />
      </Route>
    </Switch>
  </div>
);

TrainingApp.propTypes = {
  children: PropTypes.node
};

export default TrainingApp;
