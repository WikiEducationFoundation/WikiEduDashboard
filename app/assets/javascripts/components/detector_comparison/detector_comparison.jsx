import React from 'react';
import { Route, Routes } from 'react-router-dom';
import Overview from './overview';
import UnitPage from './unit_page';

// Admin page presenting the AI detector comparison data (/detector_comparison).
const DetectorComparison = () => (
  <Routes>
    <Route path="units/:id" element={<UnitPage />} />
    <Route path="*" element={<Overview />} />
  </Routes>
);

export default DetectorComparison;
