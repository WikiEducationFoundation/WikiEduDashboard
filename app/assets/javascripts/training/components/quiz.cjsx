React  = require 'react'
TrainingStore = require '../stores/training_store'
TrainingActions = require '../actions/training_actions'

Quiz = React.createClass(
  setSelectedAnswer: (e) ->
    TrainingActions.setSelectedAnswer(e.currentTarget.dataset.answerId)
  isChecked: (selectedAnswer, answerId) ->
    selectedAnswer == answerId
  render: ->
    answers = @props.answers.map (answer, i) =>
      explanationClass = "assessment__answer-explanation"
      explanationClass += if @props.correctAnswer == answer.id then ' correct' else ' incorrect'
      explanationClass += if @props.selectedAnswer == answer.id then ' shown' else ' hidden'
      isChecked = @isChecked(@props.selectedAnswer, answer.id)
      <li>
        <label>
          <input
            onChange={@setSelectedAnswer}
            data-answer-id={answer.id}
            defaultChecked={isChecked}
            checked={isChecked}
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
    </form>


)

module.exports = Quiz
