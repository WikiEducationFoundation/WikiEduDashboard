import React from 'react';
import { Route, Routes } from 'react-router-dom';
import IndexPage from './index_page';
import TopicsDataset from './topics_dataset';
import KnownHumanPage from './known_human_page';
import UnitPage from './unit_page';
import TopicPage from './topic_page';

// Public pages presenting the AI detector comparison data (/detector_comparison): an index, a
// page per dataset, a page per topic and a page per text.
const DetectorComparison = () => (
  <Routes>
    <Route path="units/:id" element={<UnitPage />} />
    <Route path="topics/:topic" element={<TopicPage />} />
    <Route path="topics" element={<TopicsDataset />} />
    <Route path="known_human" element={<KnownHumanPage />} />
    <Route path="*" element={<IndexPage />} />
  </Routes>
);

export default DetectorComparison;
