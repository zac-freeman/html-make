#!/usr/bin/perl
use strict;
use warnings;
use English;

require "./html-make.pl";

# TODO: evaluate case where provided template value is empty

# test metrics
my $successes = 0;
my $failures = 0;

# reusable variables
my $dependencyPattern = qr/DEPENDENCY\(\"([0-9a-zA-Z._\-]+)\"\)/;
my $identityPattern = qr/IDENTITY\(\"([0-9a-zA-Z._\-]+)\"\)/;

# tests equality of two given strings
# if they are equal, prints SUCCESS with given message and returns true (1)
# if they aren't equal, prints FAILURE with given message and returns false (0)
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

# sorts hash then maps it to a string representation
sub stringifyHash {
	my %hash = %{$_[0]};

	return "\{ " . join(", ", map { "\"$ARG\" => \"$hash{$ARG}\"" } sort { $a cmp $b } keys %hash) . " \}";
}

# maps array to a string representation
# TODO: ensure array order before printing
sub stringifyArray {
	my @array = @{$_[0]};

	return "[ " . join(", ", sort {$a cmp $b} @array) . " ]";
}


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
	my $message = "populateTemplate: if provided templates hash with nested, present dependencies and otherwise valid parameters, returns expected template content";
	my %templates = ( "firstTemplate" => "knock knock, DEPENDENCY(\"secondTemplate\")",
					  "secondTemplate" => "open up the door, DEPENDENCY(\"thirdTemplate\")",
					  "thirdTemplate" => "it's real, DEPENDENCY(\"fourthTemplate\")",
					  "fourthTemplate" => "with the non-stop, pop-pop of stainless steel");
	my $template = $templates{"firstTemplate"};
	my @parents = ("firstTemplate");
	my $expected = "knock knock, open up the door, it's real, with the non-stop, pop-pop of stainless steel";
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

print("\n");

# populateTemplates tests
{
	my $message = "populateTemplates: if provided templates hash with a present dependency and otherwise valid parameters, returns expected templates hash";
	my %templates = ( "parentTemplate" => "this one DEPENDENCY(\"childTemplate\") is in the middle!",
					  "childTemplate" => "it is me, the child");
	my $cycleCheckEnabled = 0;
	my $expected = "\{ \"childTemplate\" => \"it is me, the child\", \"parentTemplate\" => \"this one it is me, the child is in the middle!\" \}";
	my $actual;
	eval { $actual = stringifyHash(populateTemplates(\%templates, $dependencyPattern, $cycleCheckEnabled)); };
	$actual = $EVAL_ERROR if $EVAL_ERROR;
	assertStringEquality($expected, $actual, $message) ? $successes++ : $failures++;
}

{
	my $message = "populateTemplates: if provided templates hash with present nested dependencies and otherwise valid parameters, returns expected templates hash";
	my %templates = ("traffic" => "DEPENDENCY(\"normalCar\") - - DEPENDENCY(\"bugCar\") - - DEPENDENCY(\"normalCar\") - - DEPENDENCY(\"fancyCar\")",
					 "policeChase" => "DEPENDENCY(\"policeCarSquad\") - - - DEPENDENCY(\"normalCar\")",
					 "policeCarSquad" => "DEPENDENCY(\"policeCar\") DEPENDENCY(\"policeCar\")",
					 "policeCar" => "[8]",
					 "normalCar" => "[[]]",
					 "bugCar" => "(())",
					 "fancyCar" => "[{}]");
	my $cycleCheckEnabled = 0;
	my $expected = "\{ \"bugCar\" => \"(())\", \"fancyCar\" => \"[{}]\", \"normalCar\" => \"[[]]\", \"policeCar\" => \"[8]\", \"policeCarSquad\" => \"[8] [8]\", \"policeChase\" => \"[8] [8] - - - [[]]\", \"traffic\" => \"[[]] - - (()) - - [[]] - - [{}]\" \}";
	my $actual;
	eval { $actual = stringifyHash(populateTemplates(\%templates, $dependencyPattern, $cycleCheckEnabled)); };
	$actual = $EVAL_ERROR if $EVAL_ERROR;
	assertStringEquality($expected, $actual, $message) ? $successes++ : $failures++;
}

{
	my $message = "populateTemplates: if provided templates hash with cycle and otherwise valid parameters, throws expected exception";
	my %templates = ("selfReferentialTemplate" => "this guy ->DEPENDENCY(\"selfReferentialTemplate\")<- is GREAT");
	my $cycleCheckEnabled = 1;
	my $expected = "ERROR: Cyclic dependency found in selfReferentialTemplate -> selfReferentialTemplate\n";
	my $actual;
	eval { $actual = stringifyHash(populateTemplates(\%templates, $dependencyPattern, $cycleCheckEnabled)); };
	$actual = $EVAL_ERROR if $EVAL_ERROR;
	assertStringEquality($expected, $actual, $message) ? $successes++ : $failures++;
}

print("\n");

# identifyTemplate tests
{

	my $message = "identifyTemplate: if provided template containing one identity declaration that is alone on the first line, returns expected identity and template";
	my $template = "IDENTITY(\"bazinga\")\nThe whole universe was in a hot dense state...";
	my $expected = "[ The whole universe was in a hot dense state..., bazinga ]";
	my $actual;
	eval { $actual = stringifyArray([identifyTemplate($template, $identityPattern)]); };
	$actual = $EVAL_ERROR if $EVAL_ERROR;
	assertStringEquality($expected, $actual, $message) ? $successes++ : $failures++;
}


# final results printout
print("\nFINISHED\n");
print("    SUCCESSES - " . $successes . "\n");
print("    FAILURES - " . $failures . "\n");
