import React, { useState, useEffect } from 'react';
import StatsDisplay from './Stats_Display';
import { BarChartComponent } from './BarChartComponent';
import { LineChartComponent } from './LineChartComponent';

function Usage() {
  const StatsURL = 'http://localhost:3000/usage.json';
  const [years, setYears] = useState([]);
  const [courseData, setCourseData] = useState([]);
  const [editorsData, setEditorsData] = useState([]);
  const [leadersData, setLeadersData] = useState([]);
  const [createdData, setCreatedData] = useState([]);
  const [editedData, setEditedData] = useState([]);
  const [revisionsData, setRevisionsData] = useState([]);
  const [courseOverTime, setCourseOverTime] = useState([]);
  const fetchStats = () => {
    fetch(StatsURL)
    .then(res => res.json())
    .then((data) => {
      setYears(data.years_count);
      setCourseData(data.courses_data);
      setEditorsData(data.editors_data);
      setLeadersData(data.leaders_data);
      setCreatedData(data.created_data);
      setEditedData(data.edited_data);
      setRevisionsData(data.revisions_data);
      setCourseOverTime(data.course_over_time);
    });
  };
  useEffect(() => {
    fetchStats();
  }, []);
  return (
    <>
      <header className="main-page">
        <div className="container">
          <h1>Usage Stats</h1>
        </div>
      </header>
      <div className="course_main container">
        <div/>
        <section className="container overview">
          <StatsDisplay />
          <div/>
          <div className="primary">
            <section style={{ marginBottom: '1rem' }}>
              Courses / Programs over time
              <LineChartComponent year={years} Data={courseOverTime} Label={'Courses Over Time'}/>
            </section>
            <section>
              Yearly stats (by program creation date)
              <BarChartComponent year={years} Data={courseData} Label={'Programs'}/>
              <BarChartComponent year={years} Data={editorsData} Label={'Editors'}/>
              <BarChartComponent year={years} Data={leadersData} Label={'Program leaders'}/>
              <BarChartComponent year={years} Data={createdData} Label={'Articles Created'}/>
              <BarChartComponent year={years} Data={editedData} Label={'Articles Edited'}/>
              <BarChartComponent year={years} Data={revisionsData} Label={'Revisions'}/>
            </section>
            <section>
              <div className="section-header">
                <a className="button dark" href="/all_courses_csv">Generate CSV of all programs</a>
              </div>
            </section>
          </div>
          <div className="sidebar">
            <div>
              <div className="course-details module">
                <div className="section-header">
                  <h3>Course/Programs per Wiki :</h3>
                </div>
                <div className="module__data extra-line-height">
                  <li>
                    <a href="/courses_by_wiki/en.wikipedia.org">en.wikipedia.org: 0</a>
                  </li>
                </div>
              </div>
            </div>
          </div>
        </section>
      </div>
    </>
  );
}

export default Usage;
