import React from 'react';

class Uls extends React.Component {
  componentDidMount() {
    if ($().uls) {
      this.langSwitch = new $('.uls-trigger').uls(this.refs.langSwitch, {
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
  render() {
    return (
      <div id="langSwitch" ref="langSwitch"></div>
    );
  }
}

export default Uls;
