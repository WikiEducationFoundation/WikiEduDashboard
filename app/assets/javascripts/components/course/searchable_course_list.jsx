import React, { useEffect, useRef } from 'react';
import { useSearchParams } from 'react-router-dom';
import SearchBar from '../common/search_bar';
import { searchPrograms, sortCourseSearchResults } from '../../actions/course_actions';
import Loading from '../common/loading';
import { useDispatch, useSelector } from 'react-redux';
import CourseList from './course_list';
import CourseRow from './course_row';

// this comes from lib/revision_stat.rb
const REVISION_TIMEFRAME = 7; // this is in days

const default_course_string_prefix = Features.default_course_string_prefix;
const keys = {
  title: {
    label: I18n.t(`${default_course_string_prefix}.courses`),
  },
  school: {
    label: I18n.t(`${default_course_string_prefix}.school_and_term`),
  },
  ...(Features.wikiEd ? {
    instructor: {
      label: 'Instructor',
      sortable: false,
    }
  } : {}),
  recent_revision_count: {
    label: I18n.t('metrics.revisions'),
    info_key: 'courses.revisions_doc',
    info_key_options: { timeframe: REVISION_TIMEFRAME }
  },
  word_count: {
    label: I18n.t('metrics.word_count'),
    desktop_only: false,
    info_key: `${default_course_string_prefix}.word_count_doc`
  },
  references_count: {
    label: I18n.t('metrics.references_count'),
    desktop_only: false,
    info_key: 'metrics.references_doc'
  },
  view_sum: {
    label: I18n.t('metrics.view'),
    desktop_only: false,
    info_key: 'courses.view_doc'
  },
  user_count: {
    label: I18n.t('users.editors'),
    desktop_only: false,
  },
  ...(!Features.wikiEd ? {
    creation_date: {
      label: I18n.t('courses.creation_date'),
      desktop_only: false
    },
    timeline_start: {
      label: I18n.t('courses.timeline_start'),
      desktop_only: false
    }
  } : {}),
};

const SearchableCourseList = () => {
  const [searchParams, setSearchParams] = useSearchParams();
  const { results, loaded, sort } = useSelector(state => state.course_search_results);
  const dispatch = useDispatch();
  const searchRef = useRef();
  const search = searchParams.get('search');

  const fetchResults = () => {
    if (!searchRef.current || !searchRef?.current.value) {
      // no need to fetch results, search string is empty
      return;
    }
    dispatch(searchPrograms(searchRef?.current.value));
    setSearchParams(`?search=${searchRef?.current.value}`);
  };

  useEffect(() => {
    if (search) {
      fetchResults();
    }
  }, []);

  if (sort.key) {
    // eslint-disable-next-line no-restricted-syntax
    for (const key of Object.keys(keys)) {
      if (key === sort.key) {
        keys[sort.key].order = (sort.sortKey) ? 'asc' : 'desc';
      } else {
        keys[key].order = undefined;
      }
    }
  }

  const sortBy = (key) => {
    dispatch(sortCourseSearchResults(key));
  };
  return (
    <>
      <SearchBar onClickHandler={fetchResults} ref={searchRef} placeholder={I18n.t(`${default_course_string_prefix}.search_courses`)} value={search ?? ''} name="program-search"/>
      {search && !loaded && <Loading />}
      {search && loaded && <CourseList keys={keys} courses={results} none_message={I18n.t('application.no_results', { query: search })} sortBy={sortBy} RowElement={CourseRow}/>}
    </>
  );
};

export default SearchableCourseList;
