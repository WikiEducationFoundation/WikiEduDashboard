import React, { useState, useEffect } from 'react';
import StatsDisplay from './Stats_Display';
import { BarChartComponent } from './BarChartComponent';
import { LineChartComponent } from './LineChartComponent';

function Usage() {
  const [data, setData] = useState({
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
    fetch('/usage.json')
    .then(res => res.json())
    .then((values) => {
      setData({
        years: values.years_count,
        courseData: values.courses_data,
        editorsData: values.editors_data,
        leadersData: values.leaders_data,
        createdData: values.created_data,
        editedData: values.editedData,
        revisionsData: values.revisions_data,
        courseOverTime: values.courseOverTime,
        stats: values.stats
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
          <StatsDisplay stats={data.stats}/>
          <div/>
          <div className="primary">
            <section style={{ marginBottom: '1rem' }}>
              Courses / Programs over time
              <LineChartComponent year={data.years} Data={data.courseOverTime} Label={'Courses Over Time'}/>
            </section>
            <section>
              Yearly stats (by program creation date)
              <BarChartComponent year={data.years} Data={data.courseData} Label={'Programs'}/>
              <BarChartComponent year={data.years} Data={data.editorsData} Label={'Editors'}/>
              <BarChartComponent year={data.years} Data={data.leadersData} Label={'Program leaders'}/>
              <BarChartComponent year={data.years} Data={data.createdData} Label={'Articles Created'}/>
              <BarChartComponent year={data.years} Data={data.editedData} Label={'Articles Edited'}/>
              <BarChartComponent year={data.years} Data={data.revisionsData} Label={'Revisions'}/>
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
