# Rapidfire
[![Code Climate](https://codeclimate.com/github/code-mancers/rapidfire/badges/gpa.svg)](https://codeclimate.com/github/code-mancers/rapidfire)
[![Build Status](https://travis-ci.org/code-mancers/rapidfire.png?branch=master)](https://travis-ci.org/code-mancers/rapidfire)

One stop solution for all survey related requirements! Its tad easy!

This gem supports both **rails 3.2.13+** and **rails4** versions.

You can see a demo of this gem [here](https://rapidfire.herokuapp.com).
And the source code of demo [here](https://github.com/code-mancers/rapidfire-demo).

## Installation
Add this line to your application's Gemfile:

```rb
    gem 'rapidfire'
```

And then execute:

```shell
    $ bundle install
    $ bundle exec rake rapidfire:install:migrations
    $ bundle exec rake db:migrate
```

And if you want to customize rapidfire views, you can do

    $ bundle exec rails generate rapidfire:views

## Usage

Add this line to your routes will and you will be good to go!

```rb
    mount Rapidfire::Engine => "/rapidfire"
```

And point your browser to [http://localhost:3000/rapidfire](http://localhost:3000/rapidfire)

All rapidfire controllers inherit from your `ApplicationController`. So define 2
methods `current_user` and `can_administer?` on your `ApplicationController`

1. `current_user` : the user who is answering the survey. can be `nil`
2. `can_administer?` : a method which determines whether current user can
   create/update survey questions.

Typical implementation would be:

```rb
  class ApplicationController < ActionController::Base
    def current_user
      @current_user ||= User.find(session[:user_id])
    end

    def can_administer?
      current_user.try(:admin?)
    end
  end
```

If you are using authentication gems like devise, you get `current_user` for free
and you don't have to define it.

### Routes Information
Once this gem is mounted on, say at 'rapidfire', it generates several routes
You can see them by running `bundle exec rake routes`.

1. The `root_path` i.e `localhost:3000/rapidfire` always points to list of
   surveys {they are called question groups}. Admin can manage surveys, and
   any user {who cannot administer} can see list of surveys.
2. Optionally, each survey can by answered by visiting this path:

   ```
     localhost:3000/rapidfire/question_groups/<survey-id>/answer_groups/new
   ```

   You can distribute this url so that survey takers can answer a particular survey
   of your interest.

### Survey Results
A new api is released which helps in seeing results for each survey. The api is:

```
  GET /rapidfire/question_groups/<survey-id>/results
```
This new api supports two formats: `html` and `json`. The `json` format is supported
so that end user can use any javascript based chart solutions and render results
in the format they pleased. An example can be seen [here](https://github.com/code-mancers/rapidfire-demo),
which uses chart.js to display results.

Diving into details of `json` format, all the questions can be categorized into
one of the two categories:
1. **aggregatable**: questions like checkboxes, selects, radio buttons fall into
   this category.
2. **non-aggregatable**: questions like long answers, short answers, date, numeric
   etc.

All the aggregatable answers will be returned in the form of hash, and the
non-aggregatable answers will be returned in the form of an array. A typical json
output will be like this:

```json
[
{
    "question_type": "Rapidfire::Questions::Radio",
    "question_text": "Who is author of Waiting for godot?",
    "results": {
        "Sublime": 1,
        "Emacs": 1,
        "Vim": 1
    }
},
{
    "question_type": "Rapidfire::Questions::Checkbox",
    "question_text": "Best rock band?",
    "results": {
        "Led Zeppelin": 2
    }
},
{
    "question_type": "Rapidfire::Questions::Date",
    "question_text": "When is your birthday?",
    "results": [
        "04-02-1983",
        "01/01/1970"
    ]
},
{
    "question_type": "Rapidfire::Questions::Long",
    "question_text": "If Apple made a android phone what it will be called?",
    "results": [
        "Idude",
        "apdroid"
    ]
},
{
    "question_type": "Rapidfire::Questions::Numeric",
    "question_text": "Answer of life, universe and everything?",
    "results": [
        "42",
        "0"
    ]
},
{
    "question_type": "Rapidfire::Questions::Select",
    "question_text": "Places you want to visit after death",
    "results": {
        "Iran": 2
    }
}
]
```

## How it works
This gem gives you access to create questions in a groups, something similar to
survey. Once you have created a group and add questions to it, you can pass
around the form url where others can answer your questions.

The typical flow about how to use this gem is:

1. Create a question group by giving it a name.
2. Once group is created, you can click on the group which takes you to another
   page where you can manage questions.
3. Create a question by clicking on add new, and you will be provided by these
   options: Each question will have a type
   - **Checkbox** Create a question which contains multiple checkboxes with the
     options that you provide in `answer options` field. Note that each option
     should be on a separate line.
   - **Date** It takes date as an answer
   - **Long** It needs a description as answer. Renders a textarea.
   - **Numeric** It takes a number as an answer
   - **Radio** It renders set of radio buttons by taking answer options.
   - **Select** It renders a dropdown by taking answer options.
   - **Short** It takes a string as an answer. Short answer.

4. Once the type is filled, you can optionally fill other details like
   - **Question text** What is the question?
   - **Answer options** Give options separated by newline for questions of type
     checkbox, radio buttons or select.
   - **Answer presence** Should you mandate answering this question?
   - **min and max length** Checks whether answer if in between min and max length.
     Ignores if blank.
   - **greater than and less than** Applicable for numeric question where answer
     is validated with these values.

5. Once the questions are populated, you can return to root_path ie by clicking
   `Question Groups` and share distribute answer url so that others can answer
   the questions populated.
6. Note that answers fail to persist of the criteria that you have provided while
   creating questions fail.


## Notes on upgrading
##### Upgrading from 1.2.0 to 2.0.0

The default delimiter which is used to store options for questions like select
input, multiple answers for checkbox question is comma (,). This resulted in
problems where gem is unable to parse options properly if answers also contain
commas. For more information see [issue-19](https://github.com/code-mancers/rapidfire/issues/19).

Starting from version `2.0.0` default delimiter is changed to `\r\n`, but a
configuration is provided to change the delimiter. Please run this rake task
to make existing questions or stored answers to use new delimiter.

NOTE: Please take database backup before running this rake task.

```rb
  bundle exec rake rapidfire:change_delimiter_from_comma_to_srsn
```


If you dont want to make this change rightaway, and would like to use comma
as delimiter, then please use this initializer, but be warned that in future
delimiter will be hardcoded to `\r\n`:


```rb
  # /<path-to-app>/config/initializers/rapidfire.rb
  
  Rapidfire.config do |config|
    config.answers_delimiter = ','
  end
```


## TODO
1. Add ability to sort questions, so that order is preserved.
2. Add multi tenant support.
3. Rename question-groups to surveys, and change routes accordingly.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
