(function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);throw new Error("Cannot find module '"+o+"'")}var f=n[o]={exports:{}};t[o][0].call(f.exports,function(e){var n=t[o][1][e];return s(n?n:e)},f,f.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
$(function() {
  var articleList, courseList, userList;
  courseList = new List('courses', {
    valueNames: ['title', 'characters', 'views', 'students']
  });
  userList = new List('users', {
    valueNames: ['name', 'training', 'characters']
  });
  return articleList = new List('articles', {
    valueNames: ['title', 'characters', 'views']
  });
});


},{}],2:[function(require,module,exports){
$(function() {
  return require("./course.coffee");
});


},{"./course.coffee":1}]},{},[2])
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIi9Vc2Vycy9uYXRlYmFpbGV5L0RldmVsb3BtZW50L1dpa2lFZHVEYXNoYm9hcmQvbm9kZV9tb2R1bGVzL2d1bHAtYnJvd3NlcmlmeS9ub2RlX21vZHVsZXMvYnJvd3NlcmlmeS9ub2RlX21vZHVsZXMvYnJvd3Nlci1wYWNrL19wcmVsdWRlLmpzIiwiL1VzZXJzL25hdGViYWlsZXkvRGV2ZWxvcG1lbnQvV2lraUVkdURhc2hib2FyZC9hcHAvYXNzZXRzL2phdmFzY3JpcHRzL2NvdXJzZS5jb2ZmZWUiLCIvVXNlcnMvbmF0ZWJhaWxleS9EZXZlbG9wbWVudC9XaWtpRWR1RGFzaGJvYXJkL2FwcC9hc3NldHMvamF2YXNjcmlwdHMvbWFpbi5jb2ZmZWUiXSwibmFtZXMiOltdLCJtYXBwaW5ncyI6IkFBQUE7QUNBQSxDQUFBLENBQUUsU0FBQSxHQUFBO0FBRUEsTUFBQSxpQ0FBQTtBQUFBLEVBQUEsVUFBQSxHQUFpQixJQUFBLElBQUEsQ0FBSyxTQUFMLEVBQWdCO0FBQUEsSUFBQyxVQUFBLEVBQVksQ0FBQyxPQUFELEVBQVMsWUFBVCxFQUFzQixPQUF0QixFQUE4QixVQUE5QixDQUFiO0dBQWhCLENBQWpCLENBQUE7QUFBQSxFQUdBLFFBQUEsR0FBZSxJQUFBLElBQUEsQ0FBSyxPQUFMLEVBQWM7QUFBQSxJQUFDLFVBQUEsRUFBWSxDQUFDLE1BQUQsRUFBUSxVQUFSLEVBQW1CLFlBQW5CLENBQWI7R0FBZCxDQUhmLENBQUE7U0FNQSxXQUFBLEdBQWtCLElBQUEsSUFBQSxDQUFLLFVBQUwsRUFBaUI7QUFBQSxJQUFDLFVBQUEsRUFBWSxDQUFDLE9BQUQsRUFBUyxZQUFULEVBQXNCLE9BQXRCLENBQWI7R0FBakIsRUFSbEI7QUFBQSxDQUFGLENBQUEsQ0FBQTs7OztBQ0FBLENBQUEsQ0FBRSxTQUFBLEdBQUE7U0FDQSxPQUFBLENBQVEsaUJBQVIsRUFEQTtBQUFBLENBQUYsQ0FBQSxDQUFBIiwiZmlsZSI6ImdlbmVyYXRlZC5qcyIsInNvdXJjZVJvb3QiOiIiLCJzb3VyY2VzQ29udGVudCI6WyIoZnVuY3Rpb24gZSh0LG4scil7ZnVuY3Rpb24gcyhvLHUpe2lmKCFuW29dKXtpZighdFtvXSl7dmFyIGE9dHlwZW9mIHJlcXVpcmU9PVwiZnVuY3Rpb25cIiYmcmVxdWlyZTtpZighdSYmYSlyZXR1cm4gYShvLCEwKTtpZihpKXJldHVybiBpKG8sITApO3Rocm93IG5ldyBFcnJvcihcIkNhbm5vdCBmaW5kIG1vZHVsZSAnXCIrbytcIidcIil9dmFyIGY9bltvXT17ZXhwb3J0czp7fX07dFtvXVswXS5jYWxsKGYuZXhwb3J0cyxmdW5jdGlvbihlKXt2YXIgbj10W29dWzFdW2VdO3JldHVybiBzKG4/bjplKX0sZixmLmV4cG9ydHMsZSx0LG4scil9cmV0dXJuIG5bb10uZXhwb3J0c312YXIgaT10eXBlb2YgcmVxdWlyZT09XCJmdW5jdGlvblwiJiZyZXF1aXJlO2Zvcih2YXIgbz0wO288ci5sZW5ndGg7bysrKXMocltvXSk7cmV0dXJuIHN9KSIsIiQgLT5cbiAgIyBDb3Vyc2Ugc29ydGluZ1xuICBjb3Vyc2VMaXN0ID0gbmV3IExpc3QoJ2NvdXJzZXMnLCB7dmFsdWVOYW1lczogWyd0aXRsZScsJ2NoYXJhY3RlcnMnLCd2aWV3cycsJ3N0dWRlbnRzJ119KVxuXG4gICMgVXNlciBzb3J0aW5nXG4gIHVzZXJMaXN0ID0gbmV3IExpc3QoJ3VzZXJzJywge3ZhbHVlTmFtZXM6IFsnbmFtZScsJ3RyYWluaW5nJywnY2hhcmFjdGVycyddfSlcblxuICAjIEFydGljbGUgc29ydGluZ1xuICBhcnRpY2xlTGlzdCA9IG5ldyBMaXN0KCdhcnRpY2xlcycsIHt2YWx1ZU5hbWVzOiBbJ3RpdGxlJywnY2hhcmFjdGVycycsJ3ZpZXdzJ119KSIsIiQgLT5cbiAgcmVxdWlyZShcIi4vY291cnNlLmNvZmZlZVwiKSJdfQ==
