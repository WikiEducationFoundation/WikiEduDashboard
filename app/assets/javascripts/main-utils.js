// jQuery plugins
$.fn.extend({
  toggleHeight() {
    return this.each(function() {
      let height = '0px';
      if ($(this).css('height') === undefined || $(this).css('height') === '0px') {
        height = $(this).getContentHeight();
      }
      return $(this).css('height', height);
    });
  },

  getContentHeight() {
    let elem = $(this).clone().css({
      "height":"auto",
      "display":"block"
    }
    ).appendTo($(this).parent());
    let height = elem.css("height");
    elem.remove();
    return height;
  }
});

// Prototype additions
String.prototype.trunc = function(truncation=15) {
  if (this.length > truncation + 3) {
    return this.substring(0, truncation) + '…';
  } else {
    return this.valueOf();
  }
};

String.prototype.capitalize = function() {
  return this.charAt(0).toUpperCase() + this.slice(1);
};
