$ ->
  # Course sorting
  courseList = new List('courses', {valueNames: ['title','characters','views','students']})
  if courseList.listContainer then courseList.sort('title')

  # User sorting
  userList = new List('users', {valueNames: ['name','training','characters']})
  initial_sort(userList, '.user-list__sort', 'name')

  # Article sorting
  articleList = new List('articles', {valueNames: ['title','characters','views']})
  initial_sort(articleList, '.article-list__sort', 'title')


# Sorting helpers
sort = (list, sorter) ->
  dir = if sorter.hasClass('asc') then 'desc' else 'asc'
  list.sort(sorter.data('sort'), {order:dir})
  $('.asc, .desc').removeClass('asc desc')
  sorter.addClass(dir)

initial_sort = (list, sort_selector, sorter) ->
  if list.listContainer then list.sort(sorter)
  if $(sort_selector).length
    $('.sort[data-sort="' + sorter + '"]').addClass('asc')
    $(sort_selector + ' div').click (e) =>
      sort(list, $(e.target).parent('.sort'))