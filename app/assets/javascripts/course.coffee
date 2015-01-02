# Course sorting
courseList = new List('courses', {valueNames: [
  'title',
  'characters',
  'views',
  'students'
]})
if courseList.listContainer then courseList.sort('title')

# User sorting
userList = new List('users', {valueNames: [
  'name',
  'training',
  'characters'
]})
if userList.listContainer then userList.sort('name')
if $('.user-list__sort').length then $('.sort[data-sort="name"]').addClass('asc')
$('.user-list__sort div').click (e) =>
  sort(userList, $(e.target).parent('.sort'))

# Article sorting
articleList = new List('articles', {valueNames: [
  'title',
  'characters',
  'views'
]})
if articleList.listContainer then articleList.sort('title')
if $('.article-list__sort').length then $('.sort[data-sort="title"]').addClass('asc')
$('.article-list__sort div').click (e) =>
  sort(articleList, $(e.target).parent('.sort'))


# Sorting helper
sort = (list, sorter) ->
  dir = if sorter.hasClass('asc') then 'desc' else 'asc'
  list.sort(sorter.data('sort'), {order:dir})
  $('.asc, .desc').removeClass('asc desc')
  sorter.addClass(dir)