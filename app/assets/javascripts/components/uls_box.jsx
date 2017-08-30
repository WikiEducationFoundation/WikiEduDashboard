import React from 'react';

class Uls extends React.Component {
  attachRef() {
    this.$ls = $('.uls-trigger');
    this.$ls.uls({
      quickList: ['en', 'es', 'fr'],
      onSelect: (language) => {
        if (window.currentUser.id !== '') {
          $.post(`/update_locale/${language}`, () => {
            location.reload();
          });
        } else {
          window.location = `?locale=${language}`;
        }
      }
    });
  }

  render() {
    this.attachRef();
    return <div ref={ls => this.ls = ls} />;
  }
}

export default Uls;
