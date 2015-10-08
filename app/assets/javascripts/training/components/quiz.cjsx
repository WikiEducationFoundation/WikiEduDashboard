React  = require 'react'
TrainingStore = require '../stores/training_store'
TrainingActions = require '../actions/training_actions'

Quiz = React.createClass(
  setSelectedAnswer: (id) ->
    TrainingActions.setSelectedAnswer(id)
  verifyAnswer: (e) ->
    e.preventDefault()
    @setSelectedAnswer(@state.selectedAnswerId)
  setAnswer: (e) ->
    @setState selectedAnswerId: e.currentTarget.dataset.answerId
  componentWillReceiveProps: (newProps) ->
    @setState selectedAnswerId: newProps.selectedAnswerId
  correctStatus: (answer) ->
    if @props.correctAnswer == answer then ' correct' else ' incorrect'
  visibilityStatus: (answer) ->
    if @props.selectedAnswer == answer then ' shown' else ' hidden'
  getInitialState: ->
    selectedAnswerId: @props.selectedAnswerId
  render: ->
    answers = @props.answers.map (answer, i) =>
      explanationClass = "assessment__answer-explanation"
      explanationClass += @correctStatus(answer.id)
      explanationClass += @visibilityStatus(answer.id)
      defaultChecked = parseInt(@props.selectedAnswer) == answer.id
      checked = if @state.selectedAnswerId? then parseInt(@state.selectedAnswerId) == answer.id else defaultChecked
      <li>
        <label>
          <input
            onChange={@setAnswer}
            data-answer-id={answer.id}
            defaultChecked={defaultChecked}
            checked={checked}
            type="radio"
            name="answer" />
          {answer.text}
        </label>
        <p className={explanationClass}>{answer.explanation}</p>
      </li>

    <form className="training__slide__quiz">
      <h3>{@props.question}</h3>
      <fieldset>
        <ul>
          {answers}
        </ul>
      </fieldset>
      <button onClick={@verifyAnswer}>Check Answer</button>
    </form>


)

module.exports = Quiz
