# TODO

## SQL Scripts

- Improve the performance of the main SQL script.
- Shorten the main SQL script.
- Improve the comments on both SQL scripts.
- Make the config SQL customizable.

## Testing

- Could add pytest as a dependency to add tests along with test data (.lss files).

## Making better use of the DB

- Could make a CLI to query the DB

## Making the project generic

- Could make the project work for any game, any category, either one runner or multiple runners. Could either have one DB with multiple schemas (one schema per game + category) or one DB per game + runner, with just the public schema.

## Documentation

- Improve the docstrings.
- Write a proper and thorough `README.md`.

## Data calculation process

- Could remove outliers from the RNG pattern categorization calculations.

## Google Sheet

- Can use the API to add conditional formatting on the Google Sheet automatically to highlight trends.

## SplitsFile class

- Need to refactor it to make it cleaner and more understandable.
- Add more methods to it to cover more functionality.
- Can verify that all split files have the same split name structure as the main runners splits.
- We can automatically generate the default split names based off of the main runner, checking what split names start with "-.." and which "{..."
- We can obtain the chapter ranges automatically from the splits file itself (currently hardcoded on the SQL script).
