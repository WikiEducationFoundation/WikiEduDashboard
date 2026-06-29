import React from 'react';
import { Routes, Route } from 'react-router-dom';
import DraftList from './components/draft_list.jsx';
import DraftComposer from './components/draft_composer.jsx';

const TrainingModuleComposer = () => (
  <div className="training_module_composer container">
    <Routes>
      <Route index element={<DraftList />} />
      <Route path=":slug" element={<DraftComposer />} />
    </Routes>
  </div>
);

export default TrainingModuleComposer;
