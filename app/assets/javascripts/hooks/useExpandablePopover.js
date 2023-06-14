import { useState, useEffect, useRef } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import useOutsideClick from './useOutsideClick';
import { toggleUI } from '@actions/index';
import { ASSIGNED_ROLE } from '../constants/assignments';

const useExpandablePopover = (role, student) => {
  const openKey = useSelector(state => state.ui.openKey);
  const dispatch = useDispatch();

  const [key, setKey] = useState('');
  const [isOpen, setIsOpen] = useState(false);
  const isOpenRef = useRef();

  const getKey = () => {
    const tag = role === ASSIGNED_ROLE ? 'assign_' : 'review_';
    return student ? tag + student.id : tag;
  };

  const open = () => {
    dispatch(toggleUI(getKey()));
  };

  const handleClickOutside = () => {
    if (isOpenRef.current) {
      open();
    }
  };

  const ref = useOutsideClick(handleClickOutside);

  isOpenRef.current = isOpen;

  useEffect(() => {
    setKey(getKey());
  }, []);

  useEffect(() => {
    setIsOpen(key === openKey);
  }, [key, openKey]);

  return { isOpen, ref, open };
};

export default useExpandablePopover;
