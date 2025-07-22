import { useState, useEffect, useRef } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import useOutsideClick from './useOutsideClick';
import { toggleUI } from '@actions/index';

/*
  This is a custom hook that implements functionality for an expandable popover that closes
  on outside click. It also deals with the logic for identifying which popover is being opened.
  This should be used for functional components that require expandable popover functionality.
  For class components, use popover_expandable.jsx instead.
*/
const useExpandablePopover = (getKey) => {
  const openKey = useSelector(state => state.ui.openKey);
  const dispatch = useDispatch();

  const [key, setKey] = useState('');
  const [isOpen, setIsOpen] = useState(false);
  const isOpenRef = useRef(); // This ref is needed to avoid rerenders that can break the component state

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
