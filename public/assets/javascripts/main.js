(function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);throw new Error("Cannot find module '"+o+"'")}var f=n[o]={exports:{}};t[o][0].call(f.exports,function(e){var n=t[o][1][e];return s(n?n:e)},f,f.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
var initial_sort, sort;

$(function() {
  var articleList, courseList, userList;
  courseList = new List('courses', {
    valueNames: ['title', 'characters', 'views', 'students']
  });
  if (courseList.listContainer) {
    courseList.sort('title');
  }
  userList = new List('users', {
    valueNames: ['name', 'training', 'characters']
  });
  initial_sort(userList, '.user-list__sort', 'name');
  articleList = new List('articles', {
    valueNames: ['title', 'characters', 'views']
  });
  return initial_sort(articleList, '.article-list__sort', 'title');
});

sort = function(list, sorter) {
  var dir;
  dir = sorter.hasClass('asc') ? 'desc' : 'asc';
  list.sort(sorter.data('sort'), {
    order: dir
  });
  $('.asc, .desc').removeClass('asc desc');
  return sorter.addClass(dir);
};

initial_sort = function(list, sort_selector, sorter) {
  if (list.listContainer) {
    list.sort(sorter);
  }
  if ($(sort_selector).length) {
    $('.sort[data-sort="' + sorter + '"]').addClass('asc');
    return $(sort_selector + ' div').click((function(_this) {
      return function(e) {
        return sort(list, $(e.target).parent('.sort'));
      };
    })(this));
  }
};


},{}],2:[function(require,module,exports){
$(function() {
  return require("./course.coffee");
});


},{"./course.coffee":1}]},{},[2])
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIi9Vc2Vycy9uYXRlYmFpbGV5L0RldmVsb3BtZW50L1dpa2lFZHVEYXNoYm9hcmQvbm9kZV9tb2R1bGVzL2d1bHAtYnJvd3NlcmlmeS9ub2RlX21vZHVsZXMvYnJvd3NlcmlmeS9ub2RlX21vZHVsZXMvYnJvd3Nlci1wYWNrL19wcmVsdWRlLmpzIiwiL1VzZXJzL25hdGViYWlsZXkvRGV2ZWxvcG1lbnQvV2lraUVkdURhc2hib2FyZC9hcHAvYXNzZXRzL2phdmFzY3JpcHRzL2NvdXJzZS5jb2ZmZWUiLCIvVXNlcnMvbmF0ZWJhaWxleS9EZXZlbG9wbWVudC9XaWtpRWR1RGFzaGJvYXJkL2FwcC9hc3NldHMvamF2YXNjcmlwdHMvbWFpbi5jb2ZmZWUiXSwibmFtZXMiOltdLCJtYXBwaW5ncyI6IkFBQUE7QUNBQSxJQUFBLGtCQUFBOztBQUFBLENBQUEsQ0FBRSxTQUFBLEdBQUE7QUFFQSxNQUFBLGlDQUFBO0FBQUEsRUFBQSxVQUFBLEdBQWlCLElBQUEsSUFBQSxDQUFLLFNBQUwsRUFBZ0I7QUFBQSxJQUFDLFVBQUEsRUFBWSxDQUFDLE9BQUQsRUFBUyxZQUFULEVBQXNCLE9BQXRCLEVBQThCLFVBQTlCLENBQWI7R0FBaEIsQ0FBakIsQ0FBQTtBQUNBLEVBQUEsSUFBRyxVQUFVLENBQUMsYUFBZDtBQUFpQyxJQUFBLFVBQVUsQ0FBQyxJQUFYLENBQWdCLE9BQWhCLENBQUEsQ0FBakM7R0FEQTtBQUFBLEVBSUEsUUFBQSxHQUFlLElBQUEsSUFBQSxDQUFLLE9BQUwsRUFBYztBQUFBLElBQUMsVUFBQSxFQUFZLENBQUMsTUFBRCxFQUFRLFVBQVIsRUFBbUIsWUFBbkIsQ0FBYjtHQUFkLENBSmYsQ0FBQTtBQUFBLEVBS0EsWUFBQSxDQUFhLFFBQWIsRUFBdUIsa0JBQXZCLEVBQTJDLE1BQTNDLENBTEEsQ0FBQTtBQUFBLEVBUUEsV0FBQSxHQUFrQixJQUFBLElBQUEsQ0FBSyxVQUFMLEVBQWlCO0FBQUEsSUFBQyxVQUFBLEVBQVksQ0FBQyxPQUFELEVBQVMsWUFBVCxFQUFzQixPQUF0QixDQUFiO0dBQWpCLENBUmxCLENBQUE7U0FTQSxZQUFBLENBQWEsV0FBYixFQUEwQixxQkFBMUIsRUFBaUQsT0FBakQsRUFYQTtBQUFBLENBQUYsQ0FBQSxDQUFBOztBQUFBLElBZUEsR0FBTyxTQUFDLElBQUQsRUFBTyxNQUFQLEdBQUE7QUFDTCxNQUFBLEdBQUE7QUFBQSxFQUFBLEdBQUEsR0FBUyxNQUFNLENBQUMsUUFBUCxDQUFnQixLQUFoQixDQUFILEdBQStCLE1BQS9CLEdBQTJDLEtBQWpELENBQUE7QUFBQSxFQUNBLElBQUksQ0FBQyxJQUFMLENBQVUsTUFBTSxDQUFDLElBQVAsQ0FBWSxNQUFaLENBQVYsRUFBK0I7QUFBQSxJQUFDLEtBQUEsRUFBTSxHQUFQO0dBQS9CLENBREEsQ0FBQTtBQUFBLEVBRUEsQ0FBQSxDQUFFLGFBQUYsQ0FBZ0IsQ0FBQyxXQUFqQixDQUE2QixVQUE3QixDQUZBLENBQUE7U0FHQSxNQUFNLENBQUMsUUFBUCxDQUFnQixHQUFoQixFQUpLO0FBQUEsQ0FmUCxDQUFBOztBQUFBLFlBcUJBLEdBQWUsU0FBQyxJQUFELEVBQU8sYUFBUCxFQUFzQixNQUF0QixHQUFBO0FBQ2IsRUFBQSxJQUFHLElBQUksQ0FBQyxhQUFSO0FBQTJCLElBQUEsSUFBSSxDQUFDLElBQUwsQ0FBVSxNQUFWLENBQUEsQ0FBM0I7R0FBQTtBQUNBLEVBQUEsSUFBRyxDQUFBLENBQUUsYUFBRixDQUFnQixDQUFDLE1BQXBCO0FBQ0UsSUFBQSxDQUFBLENBQUUsbUJBQUEsR0FBc0IsTUFBdEIsR0FBK0IsSUFBakMsQ0FBc0MsQ0FBQyxRQUF2QyxDQUFnRCxLQUFoRCxDQUFBLENBQUE7V0FDQSxDQUFBLENBQUUsYUFBQSxHQUFnQixNQUFsQixDQUF5QixDQUFDLEtBQTFCLENBQWdDLENBQUEsU0FBQSxLQUFBLEdBQUE7YUFBQSxTQUFDLENBQUQsR0FBQTtlQUM5QixJQUFBLENBQUssSUFBTCxFQUFXLENBQUEsQ0FBRSxDQUFDLENBQUMsTUFBSixDQUFXLENBQUMsTUFBWixDQUFtQixPQUFuQixDQUFYLEVBRDhCO01BQUEsRUFBQTtJQUFBLENBQUEsQ0FBQSxDQUFBLElBQUEsQ0FBaEMsRUFGRjtHQUZhO0FBQUEsQ0FyQmYsQ0FBQTs7OztBQ0FBLENBQUEsQ0FBRSxTQUFBLEdBQUE7U0FDQSxPQUFBLENBQVEsaUJBQVIsRUFEQTtBQUFBLENBQUYsQ0FBQSxDQUFBIiwiZmlsZSI6ImdlbmVyYXRlZC5qcyIsInNvdXJjZVJvb3QiOiIiLCJzb3VyY2VzQ29udGVudCI6WyIoZnVuY3Rpb24gZSh0LG4scil7ZnVuY3Rpb24gcyhvLHUpe2lmKCFuW29dKXtpZighdFtvXSl7dmFyIGE9dHlwZW9mIHJlcXVpcmU9PVwiZnVuY3Rpb25cIiYmcmVxdWlyZTtpZighdSYmYSlyZXR1cm4gYShvLCEwKTtpZihpKXJldHVybiBpKG8sITApO3Rocm93IG5ldyBFcnJvcihcIkNhbm5vdCBmaW5kIG1vZHVsZSAnXCIrbytcIidcIil9dmFyIGY9bltvXT17ZXhwb3J0czp7fX07dFtvXVswXS5jYWxsKGYuZXhwb3J0cyxmdW5jdGlvbihlKXt2YXIgbj10W29dWzFdW2VdO3JldHVybiBzKG4/bjplKX0sZixmLmV4cG9ydHMsZSx0LG4scil9cmV0dXJuIG5bb10uZXhwb3J0c312YXIgaT10eXBlb2YgcmVxdWlyZT09XCJmdW5jdGlvblwiJiZyZXF1aXJlO2Zvcih2YXIgbz0wO288ci5sZW5ndGg7bysrKXMocltvXSk7cmV0dXJuIHN9KSIsIiQgLT5cbiAgIyBDb3Vyc2Ugc29ydGluZ1xuICBjb3Vyc2VMaXN0ID0gbmV3IExpc3QoJ2NvdXJzZXMnLCB7dmFsdWVOYW1lczogWyd0aXRsZScsJ2NoYXJhY3RlcnMnLCd2aWV3cycsJ3N0dWRlbnRzJ119KVxuICBpZiBjb3Vyc2VMaXN0Lmxpc3RDb250YWluZXIgdGhlbiBjb3Vyc2VMaXN0LnNvcnQoJ3RpdGxlJylcblxuICAjIFVzZXIgc29ydGluZ1xuICB1c2VyTGlzdCA9IG5ldyBMaXN0KCd1c2VycycsIHt2YWx1ZU5hbWVzOiBbJ25hbWUnLCd0cmFpbmluZycsJ2NoYXJhY3RlcnMnXX0pXG4gIGluaXRpYWxfc29ydCh1c2VyTGlzdCwgJy51c2VyLWxpc3RfX3NvcnQnLCAnbmFtZScpXG5cbiAgIyBBcnRpY2xlIHNvcnRpbmdcbiAgYXJ0aWNsZUxpc3QgPSBuZXcgTGlzdCgnYXJ0aWNsZXMnLCB7dmFsdWVOYW1lczogWyd0aXRsZScsJ2NoYXJhY3RlcnMnLCd2aWV3cyddfSlcbiAgaW5pdGlhbF9zb3J0KGFydGljbGVMaXN0LCAnLmFydGljbGUtbGlzdF9fc29ydCcsICd0aXRsZScpXG5cblxuIyBTb3J0aW5nIGhlbHBlcnNcbnNvcnQgPSAobGlzdCwgc29ydGVyKSAtPlxuICBkaXIgPSBpZiBzb3J0ZXIuaGFzQ2xhc3MoJ2FzYycpIHRoZW4gJ2Rlc2MnIGVsc2UgJ2FzYydcbiAgbGlzdC5zb3J0KHNvcnRlci5kYXRhKCdzb3J0JyksIHtvcmRlcjpkaXJ9KVxuICAkKCcuYXNjLCAuZGVzYycpLnJlbW92ZUNsYXNzKCdhc2MgZGVzYycpXG4gIHNvcnRlci5hZGRDbGFzcyhkaXIpXG5cbmluaXRpYWxfc29ydCA9IChsaXN0LCBzb3J0X3NlbGVjdG9yLCBzb3J0ZXIpIC0+XG4gIGlmIGxpc3QubGlzdENvbnRhaW5lciB0aGVuIGxpc3Quc29ydChzb3J0ZXIpXG4gIGlmICQoc29ydF9zZWxlY3RvcikubGVuZ3RoXG4gICAgJCgnLnNvcnRbZGF0YS1zb3J0PVwiJyArIHNvcnRlciArICdcIl0nKS5hZGRDbGFzcygnYXNjJylcbiAgICAkKHNvcnRfc2VsZWN0b3IgKyAnIGRpdicpLmNsaWNrIChlKSA9PlxuICAgICAgc29ydChsaXN0LCAkKGUudGFyZ2V0KS5wYXJlbnQoJy5zb3J0JykpIiwiJCAtPlxuICByZXF1aXJlKFwiLi9jb3Vyc2UuY29mZmVlXCIpIl19
