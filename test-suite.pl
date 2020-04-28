#!/usr/bin/perl
use strict;
use warnings;
use English;

require "./html-make.pl";

# test metrics
my $successes = 0;
my $failures = 0;


# functions for testing assertions
sub assertStringEquality {
	my $expected = $_[0];
	my $actual = $_[1];
	my $message = $_[2];

	if ($expected eq $actual) {
		$successes = $successes + 1;
		print("SUCCESS - " . $message . "\n");
	} else {
		$failures = $failures + 1;
		print("FAILURE - " . $message . "\n");
		print("    EXPECTED - " . $expected . "\n");
		print("    ACTUAL   - " . $actual . "\n");
	}
}


# reusable variables
my $dependencyPattern = qr/DEPENDENCY\(\"([0-9a-zA-Z._\-]+)\"\)/;


# TODO: test cyclic dependency handling and figure out a better way to organize tests
# populateTemplate tests
my $message = "populateTemplate: if provided templates hash containing a present dependency and otherwise valid parameters, returns expected template content";
my %templates = ( "rootTemplate" => "sheldon says DEPENDENCY(\"childTemplate\")",
				  "childTemplate" => "bazinga");
my $template = $templates{"rootTemplate"};
my @parents = ("rootTemplate");
my $expected = "sheldon says bazinga";
my $actual = "";
eval { $actual = populateTemplate($template, \%templates, $dependencyPattern, \@parents); };
$actual = $EVAL_ERROR if $EVAL_ERROR;
assertStringEquality($expected, $actual, $message);

$message = "populateTemplate: if provided templates hash containing a present dependency and otherwise valid parameters, does not modify original template parameter";
$expected = "sheldon says DEPENDENCY(\"childTemplate\")";
$actual = $template;
assertStringEquality($expected, $actual, $message);

$message = "populateTemplate: if provided templates hash containing single template with no dependencies and otherwise valid parameters, returns original template content";
%templates = ( "singleTemplate" => "all the single templates");
$template = $templates{"singleTemplate"};
@parents = ("singleTemplate");
$expected = $template;
$actual = "";
eval { $actual = populateTemplate($template, \%templates, $dependencyPattern, \@parents); };
$actual = $EVAL_ERROR if $EVAL_ERROR;
assertStringEquality($expected, $actual, $message);


# final results printout
print("\nFINISHED\n");
print("    SUCCESSES - " . $successes . "\n");
print("    FAILURES - " . $failures . "\n");
