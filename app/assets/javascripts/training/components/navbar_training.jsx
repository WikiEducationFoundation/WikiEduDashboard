import React from 'react';

const NavbarTraining = ({ navBreadcrumb }) => {
  let navBreadcrumbElement = null;

  if (navBreadcrumb) {
    navBreadcrumbElement = (
      <ol className="breadcrumbs" dangerouslySetInnerHTML={{ __html: navBreadcrumb }} />
    );
  }

  return (
    <div className="container">
      {navBreadcrumbElement}
    </div>
  );
};

export default NavbarTraining;
