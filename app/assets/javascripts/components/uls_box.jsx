import React from 'react';

class Uls extends React.Component {
  componentDidMount() {
    this.$ls = $('.uls-trigger');
    console.log(this.$ls);
    if ($().uls) {
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
  }
  componentWillUnmount() {
    this.$ls.uls('destroy');
  }

  render() {
    return <div ref={ls => this.ls = ls} />;
  }
}

export default Uls;
