# html-make
A Perl (five) for templating HTML without the use of javascript. Truthfully, it could be used to enable templating for any kind of text file, but HTML is one of few languages that could make use of templating and has no native support for such a thing (Rest in Peace HTML Imports, 2011-2016ish)

## Using it
There are three patterns that are recognized by the script: `IDENTITY("string")`, `DEPENDENCY("string")`, and `LOCATION("string")`.

An `IDENTITY` gives a name to a file, allowing it to be referenced in other files as a `DEPENDENCY`. Exactly one `IDENTITY` is required.

A `DEPENDENCY` is a reference to another file's `IDENTITY`. The script will replace a `DEPENDENCY` declaration with the contents of the referenced file. Any `DEPENDENCY` declarations in the referenced file will be resolved before the original `DEPENDENCY` declaration is resolved.

A `LOCATION` is a relative path that a file will be written to after all of its `DEPENDENCY` declarations are resolved. A `LOCATION` is not required for a file; if one is not provided, the contents simply will not be written anywhere. There can not be more than one `LOCATION` declared in a file.

The `DESTINATION` given in the script invocation will be prepended to each `LOCATION`.

Valid strings include all alphanumeric characters, as well as `.`, `_`, and `-`.
A valid `LOCATION` string can also include `/`. 

## Running it
This script is run on the command line and expects to be invoked in the form `perl ./html-make.pl [OPTION] SOURCE DESTINATION`.

## Testing it
Unit tests can be run with `perl ./test-suite.pl`.

A simple test of functionality can be performed with `perl ./html-make --exclude=.*swp --exclude=exact.html sample-source/ sample-output/`. There should be one file located at `./sample-output/final-template.html` containing some simple, valid, jovial HTML.

## I know
Yes, this has been done a million times before. It turns out even the [Perl docs](https://perldoc.perl.org/) are built with a Perl plaintext templating script. However, this script is lightweight and requires only the `perl` command line tool to run.

## Questions and concerns
If you're actually using this and having problems, please create an issue or message me! It would do incredible things for my ego to know that someone was voluntarily using something I wrote and I would greatly appreciate having this script "battle-tested".
