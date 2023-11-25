# Timed Times Tables

Hone your multiplication skills!

## TODO

### Make it playable for Johan

* Present the result on the start screen, with time and number of
  right-on-the-first-attempt answers

### Make it playable for others

* If the right answer hasn't been presented in five seconds, show the correct
  answer so that the player can type it
* Auto deploy to GitHub Pages on each push to the `main` branch

### Make it publishable to everyone

* Add a license
* Add contact information, both to GitHub Issues and via email
* Show the Git SHA
* Test on desktop
* Test on Android
* Test on Android in landscape mode
* Test in a small browser window on desktop
* I18N and L10N into Swedish, follow the system language

### Random improvements

* Make an icon
* Enable picking which multiplication tables to test
* Enable choosing between multiplication, division and both
* Enable setting the number of questions
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
* Based on the system language, support both Swedish and English
* Adapt to the system's theme (dark / light)
* Make the home screen look sensible on different resolutions

### Done

* Make a home screen
* Add a Start button to the home screen
* Ask ten random multiplication / division questions
* Add a text field for answer to the question
* Skip to the next question as soon as the text field contains the right answer
* After 10 questions, go back to the start screen

---

## Flutter Getting started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
