# Timed Times Tables

Hone your multiplication skills!

Try here: <https://walles.github.io/ttt>

## Development

Run tests this way. `flutter pub get` is there to regenerate localization:

```bash
flutter pub get && flutter analyze && flutter test
```

To serve the current sources on your local network so you can test on your
phone:

```bash
flutter run -d web-server --release --web-hostname 0.0.0.0 --web-port 8000 --dart-define=GIT_SHA=$(git rev-parse HEAD)
```

When it says "is being served", go to `http://<IP>:8000` on your phone, where
`<IP>` is what `ipconfig getifaddr en0` prints. If you get an old version,
reload the page.

## TODO

### Random improvements

* Make an icon
* Collect high scores
  * Individual high score tables based on tables / multiplication / division
    settings
  * Sort primarily by number of first-attempt correct answers, then by
    completion time

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
* Add contact information, both to GitHub Issues and via email
* I18N and L10N into Swedish, follow the system language
* Test on Android in a browser
* Test on desktop in a browser
* Test on Android in landscape mode
* Test in a small browser window on desktop
* Add a license
* Avoid doing the same question twice in a row
* Adapt to the system's theme (dark / light)
* When the user presses Start, start by showing a quick countdown from 3 to 1
  before starting the questions
* Add a sound effect
* Collect stats on the last 50 questions
* Present stats on the home screen, based on `LongTermStats.getTopList()`
* Pick every 4th question on average for practice, based on the latest three
  answers to each question
* Deal the other questions so that all of them come up regularly
