import React, { useState, useEffect } from 'react';
import StatsDisplay from './Stats_Display';
import { BarChartComponent } from './BarChartComponent';
import { LineChartComponent } from './LineChartComponent';

function Usage() {
  const StatsURL = '/usage.json';
  const [Data, setData] = useState({
    years: [],
    courseData: [],
    editorsData: [],
    leadersData: [],
    createdData: [],
    editedData: [],
    revisionsData: [],
    courseOverTime: [],
    stats: []
  });
  const fetchStats = () => {
    fetch(StatsURL)
    .then(res => res.json())
    .then((data) => {
      setData({
        years: data.years_count,
        courseData: data.courses_data,
        editorsData: data.editors_data,
        leadersData: data.leaders_data,
        createdData: data.created_data,
        editedData: data.editedData,
        revisionsData: data.revisions_data,
        courseOverTime: data.courseOverTime,
        stats: data.stats
      });
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
          <StatsDisplay stats={Data.stats}/>
          <div/>
          <div className="primary">
            <section style={{ marginBottom: '1rem' }}>
              Courses / Programs over time
              <LineChartComponent year={Data.years} Data={Data.courseOverTime} Label={'Courses Over Time'}/>
            </section>
            <section>
              Yearly stats (by program creation date)
              <BarChartComponent year={Data.years} Data={Data.courseData} Label={'Programs'}/>
              <BarChartComponent year={Data.years} Data={Data.editorsData} Label={'Editors'}/>
              <BarChartComponent year={Data.years} Data={Data.leadersData} Label={'Program leaders'}/>
              <BarChartComponent year={Data.years} Data={Data.createdData} Label={'Articles Created'}/>
              <BarChartComponent year={Data.years} Data={Data.editedData} Label={'Articles Edited'}/>
              <BarChartComponent year={Data.years} Data={Data.revisionsData} Label={'Revisions'}/>
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
