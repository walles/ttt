# Timed Times Tables

Hone your multiplication skills!

Try here: <https://walles.github.io/ttt>

## TODO

### Make it publishable to everyone

* Add contact information, both to GitHub Issues and via email
* Show the Git SHA
* I18N and L10N into Swedish, follow the system language
* Test on desktop in a browser
* Test on Android
* Test on Android in landscape mode
* Test in a small browser window on desktop
* Add a license

### Random improvements

* When the user presses Start, start by showing a quick countdown from 3 to 1
  before starting the questions
* Add sound effects. Steal from Numbervaders perhaps?
* Make the start screen look better when displaying stats
* Make an icon
* Avoid doing the same question twice. Might be hard with 10 questions and one
  multiplication table, let's just do our best!
* Collect high scores
  * Individual high score tables based on tables / multiplication / division
    settings
  * Sort primarily by number of first-attempt correct answers, then by
    completion time
* Keep a needs-practice list of assignments
  * When the user fails something, give it three needs-practice points
  * When the user passes something, deduct one needs-practice points
  * Try to take every other question from the needs-practice table if there's
    something in there
* Adapt to the system's theme (dark / light)
* Make the home screen look sensible on different resolutions

### Done

* Make a home screen
* Add a Start button to the home screen
* Ask ten random multiplication / division questions
* Add a text field for answer to the question
* Skip to the next question as soon as the text field contains the right answer
* After 10 questions, go back to the start screen
* Present the result on the start screen, with:
  * time
  * number of right-on-the-first-attempt answers
* Auto deploy to GitHub Pages on each push to the `main` branch
* Replace the "3/10" text with a progress bar under the line where the user
  types
* If the right answer hasn't been presented in five seconds, show the correct
  answer so that the player can type it
* Enable picking which multiplication tables to test
* Give the user 30s rather than 10 questions. Let the user finish the last
  question when the time runs out. For stats, show the user's speed in seconds
  per question.
* Replace the tables selector list with a Wrap collection ChoiseChips, one for
  each table. This should take less space and look nicer.
* Enable choosing between multiplication, division or both
