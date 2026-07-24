import React, { useState, useMemo } from 'react';
import ReactPaginate from 'react-paginate';

const ROWS_PER_PAGE = 10;

const SortIndicator = ({ field, sortField, sortOrder }) => {
  if (sortField !== field) return null;
  const indicatorClass = sortOrder === 'asc' ? 'sortable-indicator-asc' : 'sortable-indicator-desc';
  return <span className={`${indicatorClass} ${sortOrder}`} />;
};

const WikiStatsBreakdown = ({ wikiTrends, loading }) => {
  const [sortField, setSortField] = useState('edits');
  const [sortOrder, setSortOrder] = useState('desc');
  const [currentPage, setCurrentPage] = useState(0);

  const handleSort = (field) => {
    if (sortField === field) {
      setSortOrder(sortOrder === 'asc' ? 'desc' : 'asc');
    } else {
      setSortField(field);
      setSortOrder('desc');
    }
    setCurrentPage(0);
  };

  const sortedStats = useMemo(() => {
    const wikiStats = (wikiTrends && wikiTrends.wiki_stats) || [];
    return [...wikiStats].sort((a, b) => {
      const valA = a[sortField] ?? 0;
      const valB = b[sortField] ?? 0;
      if (typeof valA === 'string') {
        return sortOrder === 'asc' ? valA.localeCompare(valB) : valB.localeCompare(valA);
      }
      return sortOrder === 'asc' ? valA - valB : valB - valA;
    });
  }, [wikiTrends, sortField, sortOrder]);

  const totalPages = Math.max(1, Math.ceil(sortedStats.length / ROWS_PER_PAGE));
  const startIdx = currentPage * ROWS_PER_PAGE;
  const paginatedStats = sortedStats.slice(startIdx, startIdx + ROWS_PER_PAGE);

  return (
    <div className="module system-stats__breakdown-table">
      <div className="section-header">
        <h2>{I18n.t('system_stats.tables.wiki_breakdown')}</h2>
      </div>
      <div className="table-responsive">
        <table className="table table--sortable table--hoverable">
          <thead>
            <tr>
              <th className={`sortable${sortField === 'name' ? ` ${sortOrder}` : ''}`} onClick={() => handleSort('name')}>
                {I18n.t('system_stats.tables.wiki')}
                <SortIndicator field="name" sortField={sortField} sortOrder={sortOrder} />
              </th>
              <th className={`sortable${sortField === 'edits' ? ` ${sortOrder}` : ''}`} onClick={() => handleSort('edits')}>
                {I18n.t('system_stats.tables.edits')}
                <SortIndicator field="edits" sortField={sortField} sortOrder={sortOrder} />
              </th>
              <th className={`sortable${sortField === 'programs' ? ` ${sortOrder}` : ''}`} onClick={() => handleSort('programs')}>
                {I18n.t('system_stats.tables.programs')}
                <SortIndicator field="programs" sortField={sortField} sortOrder={sortOrder} />
              </th>
              <th className={`sortable${sortField === 'articles_created' ? ` ${sortOrder}` : ''}`} onClick={() => handleSort('articles_created')}>
                {I18n.t('system_stats.tables.articles_created')}
                <SortIndicator field="articles_created" sortField={sortField} sortOrder={sortOrder} />
              </th>
              <th className={`sortable${sortField === 'new_editors' ? ` ${sortOrder}` : ''}`} onClick={() => handleSort('new_editors')}>
                {I18n.t('system_stats.tables.new_editors')}
                <SortIndicator field="new_editors" sortField={sortField} sortOrder={sortOrder} />
              </th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr>
                <td colSpan="5" className="system-stats__table-empty">{I18n.t('system_stats.loading.wiki_stats')}</td>
              </tr>
            ) : paginatedStats.length > 0 ? (
              paginatedStats.map(w => (
                <tr key={w.name}>
                  <td>{w.name}</td>
                  <td>{w.edits.toLocaleString()}</td>
                  <td>{w.programs.toLocaleString()}</td>
                  <td>{w.articles_created.toLocaleString()}</td>
                  <td>{w.new_editors.toLocaleString()}</td>
                </tr>
              ))
            ) : (
              <tr>
                <td colSpan="5" className="system-stats__table-empty">{I18n.t('system_stats.empty.no_wiki_stats')}</td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
      {!loading && sortedStats.length > ROWS_PER_PAGE && (
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

export default WikiStatsBreakdown;
