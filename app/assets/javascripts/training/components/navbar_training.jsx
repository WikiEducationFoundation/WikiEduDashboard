import React from 'react';

const NavbarTraining = ({ navBreadcrumb }) => {
  return (
    <div className="container">
      {navBreadcrumb && <ol className="breadcrumbs" dangerouslySetInnerHTML={{ __html: navBreadcrumb }} />}
    </div>
  );
};

export default NavbarTraining;
