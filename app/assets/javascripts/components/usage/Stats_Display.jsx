import React, { useState, useEffect } from 'react';

function StatsDisplay() {
  const StatsURL = 'http://localhost:3000/usage.json';
  const [stats, setStats] = useState([]);
  const fetchStats = () => {
    fetch(StatsURL)
    .then(res => res.json())
    .then(data => setStats(data.stats));
  };
  useEffect(() => {
    fetchStats();
  }, []);
  return (
    <div className="container campaign_main">
      <section className="overview container">
        <div className="stat-display">
          {stats.map((data, id) => (
            <div key={id} className="stat-display__stat tooltip-trigger">
              <div className="stat-display__value">{data.val}</div>
              <small>{data.Name}</small>
            </div>
          ))}
        </div>
      </section>
    </div>
  );
}

export default StatsDisplay;
