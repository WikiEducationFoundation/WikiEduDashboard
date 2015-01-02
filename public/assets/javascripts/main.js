(function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);throw new Error("Cannot find module '"+o+"'")}var f=n[o]={exports:{}};t[o][0].call(f.exports,function(e){var n=t[o][1][e];return s(n?n:e)},f,f.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
var articleList, courseList, sort, userList;

courseList = new List('courses', {
  valueNames: ['title', 'characters', 'views', 'students']
});

if (courseList.listContainer) {
  courseList.sort('title');
}

userList = new List('users', {
  valueNames: ['name', 'training', 'characters']
});

if (userList.listContainer) {
  userList.sort('name');
}

if ($('.user-list__sort').length) {
  $('.sort[data-sort="name"]').addClass('asc');
}

$('.user-list__sort div').click((function(_this) {
  return function(e) {
    return sort(userList, $(e.target).parent('.sort'));
  };
})(this));

articleList = new List('articles', {
  valueNames: ['title', 'characters', 'views']
});

if (articleList.listContainer) {
  articleList.sort('title');
}

if ($('.article-list__sort').length) {
  $('.sort[data-sort="title"]').addClass('asc');
}

$('.article-list__sort div').click((function(_this) {
  return function(e) {
    return sort(articleList, $(e.target).parent('.sort'));
  };
})(this));

sort = function(list, sorter) {
  var dir;
  dir = sorter.hasClass('asc') ? 'desc' : 'asc';
  list.sort(sorter.data('sort'), {
    order: dir
  });
  $('.asc, .desc').removeClass('asc desc');
  return sorter.addClass(dir);
};


},{}],2:[function(require,module,exports){
$(function() {
  return require("./course.coffee");
});


},{"./course.coffee":1}]},{},[2])
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIi9Vc2Vycy9uYXRlYmFpbGV5L0RldmVsb3BtZW50L1dpa2lFZHVEYXNoYm9hcmQvbm9kZV9tb2R1bGVzL2d1bHAtYnJvd3NlcmlmeS9ub2RlX21vZHVsZXMvYnJvd3NlcmlmeS9ub2RlX21vZHVsZXMvYnJvd3Nlci1wYWNrL19wcmVsdWRlLmpzIiwiL1VzZXJzL25hdGViYWlsZXkvRGV2ZWxvcG1lbnQvV2lraUVkdURhc2hib2FyZC9hcHAvYXNzZXRzL2phdmFzY3JpcHRzL2NvdXJzZS5jb2ZmZWUiLCIvVXNlcnMvbmF0ZWJhaWxleS9EZXZlbG9wbWVudC9XaWtpRWR1RGFzaGJvYXJkL2FwcC9hc3NldHMvamF2YXNjcmlwdHMvbWFpbi5jb2ZmZWUiXSwibmFtZXMiOltdLCJtYXBwaW5ncyI6IkFBQUE7QUNDQSxJQUFBLHVDQUFBOztBQUFBLFVBQUEsR0FBaUIsSUFBQSxJQUFBLENBQUssU0FBTCxFQUFnQjtBQUFBLEVBQUMsVUFBQSxFQUFZLENBQzVDLE9BRDRDLEVBRTVDLFlBRjRDLEVBRzVDLE9BSDRDLEVBSTVDLFVBSjRDLENBQWI7Q0FBaEIsQ0FBakIsQ0FBQTs7QUFNQSxJQUFHLFVBQVUsQ0FBQyxhQUFkO0FBQWlDLEVBQUEsVUFBVSxDQUFDLElBQVgsQ0FBZ0IsT0FBaEIsQ0FBQSxDQUFqQztDQU5BOztBQUFBLFFBU0EsR0FBZSxJQUFBLElBQUEsQ0FBSyxPQUFMLEVBQWM7QUFBQSxFQUFDLFVBQUEsRUFBWSxDQUN4QyxNQUR3QyxFQUV4QyxVQUZ3QyxFQUd4QyxZQUh3QyxDQUFiO0NBQWQsQ0FUZixDQUFBOztBQWNBLElBQUcsUUFBUSxDQUFDLGFBQVo7QUFBK0IsRUFBQSxRQUFRLENBQUMsSUFBVCxDQUFjLE1BQWQsQ0FBQSxDQUEvQjtDQWRBOztBQWVBLElBQUcsQ0FBQSxDQUFFLGtCQUFGLENBQXFCLENBQUMsTUFBekI7QUFBcUMsRUFBQSxDQUFBLENBQUUseUJBQUYsQ0FBNEIsQ0FBQyxRQUE3QixDQUFzQyxLQUF0QyxDQUFBLENBQXJDO0NBZkE7O0FBQUEsQ0FnQkEsQ0FBRSxzQkFBRixDQUF5QixDQUFDLEtBQTFCLENBQWdDLENBQUEsU0FBQSxLQUFBLEdBQUE7U0FBQSxTQUFDLENBQUQsR0FBQTtXQUM5QixJQUFBLENBQUssUUFBTCxFQUFlLENBQUEsQ0FBRSxDQUFDLENBQUMsTUFBSixDQUFXLENBQUMsTUFBWixDQUFtQixPQUFuQixDQUFmLEVBRDhCO0VBQUEsRUFBQTtBQUFBLENBQUEsQ0FBQSxDQUFBLElBQUEsQ0FBaEMsQ0FoQkEsQ0FBQTs7QUFBQSxXQW9CQSxHQUFrQixJQUFBLElBQUEsQ0FBSyxVQUFMLEVBQWlCO0FBQUEsRUFBQyxVQUFBLEVBQVksQ0FDOUMsT0FEOEMsRUFFOUMsWUFGOEMsRUFHOUMsT0FIOEMsQ0FBYjtDQUFqQixDQXBCbEIsQ0FBQTs7QUF5QkEsSUFBRyxXQUFXLENBQUMsYUFBZjtBQUFrQyxFQUFBLFdBQVcsQ0FBQyxJQUFaLENBQWlCLE9BQWpCLENBQUEsQ0FBbEM7Q0F6QkE7O0FBMEJBLElBQUcsQ0FBQSxDQUFFLHFCQUFGLENBQXdCLENBQUMsTUFBNUI7QUFBd0MsRUFBQSxDQUFBLENBQUUsMEJBQUYsQ0FBNkIsQ0FBQyxRQUE5QixDQUF1QyxLQUF2QyxDQUFBLENBQXhDO0NBMUJBOztBQUFBLENBMkJBLENBQUUseUJBQUYsQ0FBNEIsQ0FBQyxLQUE3QixDQUFtQyxDQUFBLFNBQUEsS0FBQSxHQUFBO1NBQUEsU0FBQyxDQUFELEdBQUE7V0FDakMsSUFBQSxDQUFLLFdBQUwsRUFBa0IsQ0FBQSxDQUFFLENBQUMsQ0FBQyxNQUFKLENBQVcsQ0FBQyxNQUFaLENBQW1CLE9BQW5CLENBQWxCLEVBRGlDO0VBQUEsRUFBQTtBQUFBLENBQUEsQ0FBQSxDQUFBLElBQUEsQ0FBbkMsQ0EzQkEsQ0FBQTs7QUFBQSxJQWdDQSxHQUFPLFNBQUMsSUFBRCxFQUFPLE1BQVAsR0FBQTtBQUNMLE1BQUEsR0FBQTtBQUFBLEVBQUEsR0FBQSxHQUFTLE1BQU0sQ0FBQyxRQUFQLENBQWdCLEtBQWhCLENBQUgsR0FBK0IsTUFBL0IsR0FBMkMsS0FBakQsQ0FBQTtBQUFBLEVBQ0EsSUFBSSxDQUFDLElBQUwsQ0FBVSxNQUFNLENBQUMsSUFBUCxDQUFZLE1BQVosQ0FBVixFQUErQjtBQUFBLElBQUMsS0FBQSxFQUFNLEdBQVA7R0FBL0IsQ0FEQSxDQUFBO0FBQUEsRUFFQSxDQUFBLENBQUUsYUFBRixDQUFnQixDQUFDLFdBQWpCLENBQTZCLFVBQTdCLENBRkEsQ0FBQTtTQUdBLE1BQU0sQ0FBQyxRQUFQLENBQWdCLEdBQWhCLEVBSks7QUFBQSxDQWhDUCxDQUFBOzs7O0FDREEsQ0FBQSxDQUFFLFNBQUEsR0FBQTtTQUNBLE9BQUEsQ0FBUSxpQkFBUixFQURBO0FBQUEsQ0FBRixDQUFBLENBQUEiLCJmaWxlIjoiZ2VuZXJhdGVkLmpzIiwic291cmNlUm9vdCI6IiIsInNvdXJjZXNDb250ZW50IjpbIihmdW5jdGlvbiBlKHQsbixyKXtmdW5jdGlvbiBzKG8sdSl7aWYoIW5bb10pe2lmKCF0W29dKXt2YXIgYT10eXBlb2YgcmVxdWlyZT09XCJmdW5jdGlvblwiJiZyZXF1aXJlO2lmKCF1JiZhKXJldHVybiBhKG8sITApO2lmKGkpcmV0dXJuIGkobywhMCk7dGhyb3cgbmV3IEVycm9yKFwiQ2Fubm90IGZpbmQgbW9kdWxlICdcIitvK1wiJ1wiKX12YXIgZj1uW29dPXtleHBvcnRzOnt9fTt0W29dWzBdLmNhbGwoZi5leHBvcnRzLGZ1bmN0aW9uKGUpe3ZhciBuPXRbb11bMV1bZV07cmV0dXJuIHMobj9uOmUpfSxmLGYuZXhwb3J0cyxlLHQsbixyKX1yZXR1cm4gbltvXS5leHBvcnRzfXZhciBpPXR5cGVvZiByZXF1aXJlPT1cImZ1bmN0aW9uXCImJnJlcXVpcmU7Zm9yKHZhciBvPTA7bzxyLmxlbmd0aDtvKyspcyhyW29dKTtyZXR1cm4gc30pIiwiIyBDb3Vyc2Ugc29ydGluZ1xuY291cnNlTGlzdCA9IG5ldyBMaXN0KCdjb3Vyc2VzJywge3ZhbHVlTmFtZXM6IFtcbiAgJ3RpdGxlJyxcbiAgJ2NoYXJhY3RlcnMnLFxuICAndmlld3MnLFxuICAnc3R1ZGVudHMnXG5dfSlcbmlmIGNvdXJzZUxpc3QubGlzdENvbnRhaW5lciB0aGVuIGNvdXJzZUxpc3Quc29ydCgndGl0bGUnKVxuXG4jIFVzZXIgc29ydGluZ1xudXNlckxpc3QgPSBuZXcgTGlzdCgndXNlcnMnLCB7dmFsdWVOYW1lczogW1xuICAnbmFtZScsXG4gICd0cmFpbmluZycsXG4gICdjaGFyYWN0ZXJzJ1xuXX0pXG5pZiB1c2VyTGlzdC5saXN0Q29udGFpbmVyIHRoZW4gdXNlckxpc3Quc29ydCgnbmFtZScpXG5pZiAkKCcudXNlci1saXN0X19zb3J0JykubGVuZ3RoIHRoZW4gJCgnLnNvcnRbZGF0YS1zb3J0PVwibmFtZVwiXScpLmFkZENsYXNzKCdhc2MnKVxuJCgnLnVzZXItbGlzdF9fc29ydCBkaXYnKS5jbGljayAoZSkgPT5cbiAgc29ydCh1c2VyTGlzdCwgJChlLnRhcmdldCkucGFyZW50KCcuc29ydCcpKVxuXG4jIEFydGljbGUgc29ydGluZ1xuYXJ0aWNsZUxpc3QgPSBuZXcgTGlzdCgnYXJ0aWNsZXMnLCB7dmFsdWVOYW1lczogW1xuICAndGl0bGUnLFxuICAnY2hhcmFjdGVycycsXG4gICd2aWV3cydcbl19KVxuaWYgYXJ0aWNsZUxpc3QubGlzdENvbnRhaW5lciB0aGVuIGFydGljbGVMaXN0LnNvcnQoJ3RpdGxlJylcbmlmICQoJy5hcnRpY2xlLWxpc3RfX3NvcnQnKS5sZW5ndGggdGhlbiAkKCcuc29ydFtkYXRhLXNvcnQ9XCJ0aXRsZVwiXScpLmFkZENsYXNzKCdhc2MnKVxuJCgnLmFydGljbGUtbGlzdF9fc29ydCBkaXYnKS5jbGljayAoZSkgPT5cbiAgc29ydChhcnRpY2xlTGlzdCwgJChlLnRhcmdldCkucGFyZW50KCcuc29ydCcpKVxuXG5cbiMgU29ydGluZyBoZWxwZXJcbnNvcnQgPSAobGlzdCwgc29ydGVyKSAtPlxuICBkaXIgPSBpZiBzb3J0ZXIuaGFzQ2xhc3MoJ2FzYycpIHRoZW4gJ2Rlc2MnIGVsc2UgJ2FzYydcbiAgbGlzdC5zb3J0KHNvcnRlci5kYXRhKCdzb3J0JyksIHtvcmRlcjpkaXJ9KVxuICAkKCcuYXNjLCAuZGVzYycpLnJlbW92ZUNsYXNzKCdhc2MgZGVzYycpXG4gIHNvcnRlci5hZGRDbGFzcyhkaXIpIiwiJCAtPlxuICByZXF1aXJlKFwiLi9jb3Vyc2UuY29mZmVlXCIpIl19
