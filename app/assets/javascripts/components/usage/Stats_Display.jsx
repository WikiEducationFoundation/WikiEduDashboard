import React from 'react';

function StatsDisplay({ stats }) {
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
