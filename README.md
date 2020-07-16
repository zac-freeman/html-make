# html-make
A Perl (five) script designed to enable templating of HTML without the use of javascript. Truthfully, it could be used to enable templating for any kind of text file, but HTML is one of few languages that could make use of templating and has no native support for such a thing (Rest in Peace HTML Imports, 2011-2016ish)

## I know
Yes, this has been done a million times before. It turns out even the [Perl docs](https://perldoc.perl.org/) are built with a Perl plaintext templating script. However, this script is lightweight and requires only the `perl` command line tool to run.

## Running it
This script is run on the command line and expects to be invoked in the form `perl ./html-make.pl [OPTION] SOURCE DESTINATION`.

## Testing it
Unit tests can be run with `perl ./test-suite.pl`.

A simple test of functionality can be performed with `perl ./html-make sample-source/ sample-output/`. There should be one file located at ./sample-output/final-template.html containing some simple, valid, jovial HTML.

## Questions and concerns
If you're actually using this and having problems, please create an issue or message me! It would do incredible things for my ego to know that someone was voluntarily using something I wrote and I would greatly appreciate having this script "battle-tested".
