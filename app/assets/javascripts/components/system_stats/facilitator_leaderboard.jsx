import React, { useState, useEffect } from 'react';
import ReactPaginate from 'react-paginate';
import request from '../../utils/request';

const ROWS_PER_PAGE = 10;

const SortIndicator = ({ field, sortField, sortOrder }) => {
  if (sortField !== field) return null;
  const indicatorClass = sortOrder === 'asc' ? 'sortable-indicator-asc' : 'sortable-indicator-desc';
  return <span className={`${indicatorClass} ${sortOrder}`} />;
};

const FacilitatorLeaderboard = () => {
  const [facilitators, setFacilitators] = useState(null);
  const [loading, setLoading] = useState(true);
  const [sortField, setSortField] = useState('edits');
  const [sortOrder, setSortOrder] = useState('desc');
  const [error, setError] = useState(null);
  const [currentPage, setCurrentPage] = useState(0);

  useEffect(() => {
    setLoading(true);
    request('/system_stats/facilitators.json')
      .then(resp => {
        if (!resp.ok) {
          throw new Error('Failed to fetch facilitators');
        }
        return resp.json();
      })
      .then(data => {
        setFacilitators(data.facilitators);
        setLoading(false);
      })
      .catch(err => {
        console.error(err);
        setError(I18n.t('system_stats.errors.fetch_failed'));
        setLoading(false);
      });
  }, []);

  const handleSort = (field) => {
    if (sortField === field) {
      setSortOrder(sortOrder === 'asc' ? 'desc' : 'asc');
    } else {
      setSortField(field);
      setSortOrder('desc');
    }
    setCurrentPage(0);
  };

  const sortedFacilitators = [...(facilitators || [])]
    .sort((a, b) => {
      let valA = a[sortField];
      let valB = b[sortField];
      if (typeof valA === 'string') {
        return sortOrder === 'asc' ? valA.localeCompare(valB) : valB.localeCompare(valA);
      }
      return sortOrder === 'asc' ? valA - valB : valB - valA;
    });

  const totalPages = Math.max(1, Math.ceil(sortedFacilitators.length / ROWS_PER_PAGE));
  const startIdx = currentPage * ROWS_PER_PAGE;
  const paginatedFacilitators = sortedFacilitators.slice(startIdx, startIdx + ROWS_PER_PAGE);

  return (
    <div id="facilitators" className="container">
      <div className="section-header system-stats__leaderboard-header">
        <h2>{I18n.t('system_stats.facilitators.title')}</h2>
      </div>
      {error && (
        <div className="notification" role="alert">
          <div className="container">
            <p>{error}</p>
          </div>
        </div>
      )}
      <div className="table-responsive">
        <table className="table table--sortable table--hoverable">
          <thead>
            <tr>
              <th className={`sortable${sortField === 'username' ? ` ${sortOrder}` : ''}`} onClick={() => handleSort('username')}>
                {I18n.t('system_stats.facilitators.username')}
                <SortIndicator field="username" sortField={sortField} sortOrder={sortOrder} />
              </th>
              <th className={`sortable${sortField === 'courses' ? ` ${sortOrder}` : ''}`} onClick={() => handleSort('courses')}>
                {I18n.t('system_stats.facilitators.courses')}
                <SortIndicator field="courses" sortField={sortField} sortOrder={sortOrder} />
              </th>
              <th className={`sortable${sortField === 'activeCourses' ? ` ${sortOrder}` : ''}`} onClick={() => handleSort('activeCourses')}>
                {I18n.t('system_stats.facilitators.active')}
                <SortIndicator field="activeCourses" sortField={sortField} sortOrder={sortOrder} />
              </th>
              <th className={`sortable${sortField === 'edits' ? ` ${sortOrder}` : ''}`} onClick={() => handleSort('edits')}>
                {I18n.t('system_stats.tables.edits')}
                <SortIndicator field="edits" sortField={sortField} sortOrder={sortOrder} />
              </th>
              <th className={`sortable${sortField === 'students' ? ` ${sortOrder}` : ''}`} onClick={() => handleSort('students')}>
                {I18n.t('system_stats.facilitators.students')}
                <SortIndicator field="students" sortField={sortField} sortOrder={sortOrder} />
              </th>
              <th className={`sortable${sortField === 'newEditors' ? ` ${sortOrder}` : ''}`} onClick={() => handleSort('newEditors')}>
                {I18n.t('system_stats.kpis.new_editors')}
                <SortIndicator field="newEditors" sortField={sortField} sortOrder={sortOrder} />
              </th>
              <th className={`sortable${sortField === 'activeInYear' ? ` ${sortOrder}` : ''}`} onClick={() => handleSort('activeInYear')}>
                {I18n.t('system_stats.facilitators.active_in_year')}
                <SortIndicator field="activeInYear" sortField={sortField} sortOrder={sortOrder} />
              </th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr>
                <td colSpan="7" className="system-stats__table-empty">{I18n.t('system_stats.loading.facilitators')}</td>
              </tr>
            ) : paginatedFacilitators.length > 0 ? (
              paginatedFacilitators.map(f => (
                <tr key={f.username}>
                  <td>{f.username}</td>
                  <td>{f.courses}</td>
                  <td>{f.activeCourses}</td>
                  <td>{f.edits.toLocaleString()}</td>
                  <td>{f.students}</td>
                  <td>{f.newEditors}</td>
                  <td>{f.activeInYear}</td>
                </tr>
              ))
            ) : (
              <tr>
                <td colSpan="7" className="system-stats__table-empty">{I18n.t('system_stats.empty.no_facilitators')}</td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
      {!loading && sortedFacilitators.length > ROWS_PER_PAGE && (
        <ReactPaginate
          previousLabel={I18n.t('system_stats.pagination.previous')}
          nextLabel={I18n.t('system_stats.pagination.next')}
          breakLabel="..."
          pageCount={totalPages}
          marginPagesDisplayed={2}
          pageRangeDisplayed={6}
          onPageChange={({ selected }) => setCurrentPage(selected)}
          forcePage={currentPage}
          containerClassName={'pagination'}
        />
      )}
    </div>
  );
};

export default FacilitatorLeaderboard;
