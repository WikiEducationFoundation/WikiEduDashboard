React           = require 'react/addons'

DYKArticle = React.createClass
  render: ->
    <tr className='dyk-article closed'>
      <td>
        {@props.title}
      </td>
      <td>
        {@props.revisionScore}
      </td>
      <td>
        <a href="https://en.wikipedia.org/wiki/User_talk:#{@props.author}">{@props.author}</a>
      </td>
      <td>
        {@props.revisionDateTime}
      </td>
      <td>
        <button className='icon icon-arrow'></button>
      </td>
    </tr>

module.exports = DYKArticle
