#!/usr/bin/perl
use strict;
use warnings;

require "./html-make.pl";

my $successes = 0;	# number of tests that succeeded
my $failures = 0;	# number of tests that failed

my %singleElementTemplatesHash = ();
my %cyclicDependencyTemplatesHash = ();
my %emptyTemplatesHash = ();

# populateTemplate: if provided valid parameters, returns expected template content
my %validTemplates = ( "rootTemplate" => "sheldon says DEPENDENCY(\"childTemplate\")",
					   "childTemplate" => "bazinga");
my $validTemplate = $validTemplates{"rootTemplate"};
my $validDependencyPattern = qr/DEPENDENCY\(\"([0-9a-zA-Z._\-]+)\"\)/;
my @validParents = ("rootTemplate");

my $expected = "sheldon says bazinga";
my $actual = populateTemplate($validTemplate, \%validTemplates, $validDependencyPattern, \@validParents);

if ($expected eq $actual) {
	$successes = $successes + 1;
	print("SUCCESS - populateTemplate: if provided valid parameters, returns expected template content\n");
} else {
	$failures = $failures + 1;
	print("FAILURE - populateTemplate: if provided valid parameters, returns expected template content\n");
	print("    EXPECTED - " . $expected . "\n");
	print("    ACTUAL   - " . $actual . "\n");
}

print("\nFINISHED\n");
print("    SUCCESSES - " . $successes . "\n");
print("    FAILURES - " . $failures . "\n");
