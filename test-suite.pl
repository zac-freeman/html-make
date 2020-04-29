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
		print("SUCCESS - " . $message . "\n");
		return 1;
	} else {
		print("FAILURE - " . $message . "\n");
		print("    EXPECTED - " . $expected . "\n");
		print("    ACTUAL   - " . $actual . "\n");
		return 0;
	}
}


# reusable variables
my $dependencyPattern = qr/DEPENDENCY\(\"([0-9a-zA-Z._\-]+)\"\)/;


# populateTemplate tests
{
	my $message = "populateTemplate: if provided templates hash containing a present dependency and otherwise valid parameters, returns expected template content";
	my %templates = ( "rootTemplate" => "sheldon says DEPENDENCY(\"childTemplate\")",
					  "childTemplate" => "bazinga");
	my $template = $templates{"rootTemplate"};
	my @parents = ("rootTemplate");
	my $expected = "sheldon says bazinga";
	my $actual;
	eval { $actual = populateTemplate($template, \%templates, $dependencyPattern, \@parents); };
	$actual = $EVAL_ERROR if $EVAL_ERROR;
	assertStringEquality($expected, $actual, $message) ? $successes++ : $failures++;
}

{
	my $message = "populateTemplate: if provided an empty parents array and otherwise valid parameters, returns expected template content";
	my %templates = ( "rootTemplate" => "sheldon says DEPENDENCY(\"childTemplate\")",
					  "childTemplate" => "bazinga");
	my $template = $templates{"rootTemplate"};
	my @parents;
	my $expected = "sheldon says bazinga";
	my $actual;
	eval { $actual = populateTemplate($template, \%templates, $dependencyPattern, \@parents); };
	$actual = $EVAL_ERROR if $EVAL_ERROR;
	assertStringEquality($expected, $actual, $message) ? $successes++ : $failures++;
}

{
	my $message = "populateTemplate: if provided templates hash containing a present dependency and otherwise valid parameters, does not modify original template parameter";
	my %templates = ( "rootTemplate" => "sheldon says DEPENDENCY(\"childTemplate\")",
					  "childTemplate" => "bazinga");
	my $template = $templates{"rootTemplate"};
	my @parents = ("rootTemplate");
	my $expected = $templates{"rootTemplate"};
	eval { populateTemplate($template, \%templates, $dependencyPattern, \@parents); };
	my $actual = $templates{"rootTemplate"};
	$actual = $EVAL_ERROR if $EVAL_ERROR;
	assertStringEquality($expected, $actual, $message) ? $successes++ : $failures++;
}

{
	my $message = "populateTemplate: if provided templates hash containing a cyclic dependency and otherwise valid parameters, throws expected exception";
	my %templates = ( "rootTemplate" => "sheldon says DEPENDENCY(\"childTemplate\")",
					  "childTemplate" => "penny says DEPENDENCY(\"rootTemplate\")");
	my $template = $templates{"rootTemplate"};
	my @parents = ("rootTemplate");
	my $expected = "ERROR: Cyclic dependency found in rootTemplate -> childTemplate -> rootTemplate\n";
	my $actual;
	eval { $actual = populateTemplate($template, \%templates, $dependencyPattern, \@parents); };
	$actual = $EVAL_ERROR if $EVAL_ERROR;
	assertStringEquality($expected, $actual, $message) ? $successes++ : $failures++;
}

{
	my $message = "populateTemplate: if provided templates hash containing single template with no dependencies and otherwise valid parameters, returns original template content";
	my %templates = ( "singleTemplate" => "all the single templates");
	my $template = $templates{"singleTemplate"};
	my @parents = ("singleTemplate");
	my $expected = $template;
	my $actual;
	eval { $actual = populateTemplate($template, \%templates, $dependencyPattern, \@parents); };
	$actual = $EVAL_ERROR if $EVAL_ERROR;
	assertStringEquality($expected, $actual, $message) ? $successes++ : $failures++;
}

{
	my $message = "populateTemplate: if provided templates hash containing a template with a missing dependency and otherwise valid parameters, throws expected exception";
	my %templates = ( "singleTemplate" => "all the lonely templates, DEPENDENCY(\"where\") do they all come from");
	my $template = $templates{"singleTemplate"};
	my @parents = ("singleTemplate");
	my $expected = "ERROR: No template found in templates hash with name \"where\"\n";
	my $actual;
	eval { $actual = populateTemplate($template, \%templates, $dependencyPattern, \@parents); };
	$actual = $EVAL_ERROR if $EVAL_ERROR;
	assertStringEquality($expected, $actual, $message) ? $successes++ : $failures++;
}


# final results printout
print("\nFINISHED\n");
print("    SUCCESSES - " . $successes . "\n");
print("    FAILURES - " . $failures . "\n");
