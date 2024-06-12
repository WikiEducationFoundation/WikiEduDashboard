import React, { useState } from 'react';
import useOutsideClick from '../../../hooks/useOutsideClick';
import NewsNavIcon from './news_nav_icon';
import NewsPopoverHandler from './news_popover_handler';

// The NewsHandler component is responsible for managing the state of the news popover
// and handling the click outside logic to close the popover.
const NewsHandler = () => {
  // State to track whether the news popover is open or closed
  const [isOpen, setIsOpen] = useState(false);

  // Function to close the popover when clicked outside
  const closePopoverOnClickOutside = () => {
    setIsOpen(false);
  };

  // Custom hook to handle click outside event and call the closePopoverOnClickOutside function
  const closeNewsPopover = useOutsideClick(closePopoverOnClickOutside);

  return (
    <span ref={closeNewsPopover}>
      <NewsNavIcon setIsOpen={setIsOpen} />
      {/* Conditionally render the NewsPopoverHandler component if isOpen is true */}
      {isOpen && <NewsPopoverHandler />}
    </span>
  );
};

export default NewsHandler;
