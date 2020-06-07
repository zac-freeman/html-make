#!/usr/bin/perl
use strict;
use warnings;
use English;

require "./html-make.pl";

# test metrics
my $successes = 0;
my $failures = 0;

# reusable variables
my $dependencyPattern = qr/DEPENDENCY\(\"([0-9a-zA-Z._\-]+)\"\)/;
my $identityPattern = qr/IDENTITY\(\"([0-9a-zA-Z._\-]+)\"\)/;

# tests equality of two given strings
# if they are equal, prints SUCCESS with given message, then returns true (1)
# if they aren't equal, prints FAILURE with given message and newline-escaped comparison, then returns false (0)
sub assertStringEquality {
	my $expected = $_[0];
	my $actual = $_[1];
	my $message = $_[2];

	if ($expected eq $actual) {
		print("SUCCESS - " . $message . "\n");
		return 1;
	} else {
		print("FAILURE - " . $message . "\n");
		print("    EXPECTED - " . $expected =~ s/\n/\\n/rg . "\n");
		print("    ACTUAL   - " . $actual =~ s/\n/\\n/rg . "\n");
		return 0;
	}
}

# sorts hash then maps it to a string representation
sub stringifyHash {
	my %hash = %{$_[0]};

	return "\{ " . join(", ", map { "\"$ARG\" => \"$hash{$ARG}\"" } sort { $a cmp $b } keys %hash) . " \}";
}

# maps array to a string representation
sub stringifyArray {
	my @array = @{$_[0]};

	return "[ " . join(", ", map { "\"$ARG\"" } sort {$a cmp $b} @array) . " ]";
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
	my $expected = "sheldon says DEPENDENCY(\"childTemplate\")";
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

{
	my $message = "populateTemplate: if provided templates hash containing an empty dependency and otherwise valid parameters, returns expected template content";
	my %templates = ( "dependentTemplate" => "DEPENDENCY(\"emptyTemplate\")you saw nothing",
					  "emptyTemplate" => "" );
	my $template = $templates{"dependentTemplate"};
	my @parents = ();
	my $expected = "you saw nothing";
	my $actual;
	eval { $actual = populateTemplate($template, \%templates, $dependencyPattern, \@parents) };
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
	my %templates = ( "traffic" => "DEPENDENCY(\"normalCar\") - - DEPENDENCY(\"bugCar\") - - DEPENDENCY(\"normalCar\") - - DEPENDENCY(\"fancyCar\")",
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
	my $expected = "[ \"The whole universe was in a hot dense state...\", \"bazinga\" ]";
	my $actual;
	eval { $actual = stringifyArray([identifyTemplate($template, $identityPattern)]); };
	$actual = $EVAL_ERROR if $EVAL_ERROR;
	assertStringEquality($expected, $actual, $message) ? $successes++ : $failures++;
}

{
	my $message = "identifyTemplate: if provided template containing one identity declaration alone on the middle line, returns expected identity and template";
	my $template = "this is the first line\nIDENTITY(\"middle\")\nthis is the last line";
	my $expected = "[ \"middle\", \"this is the first line\nthis is the last line\" ]";
	my $actual;
	eval { $actual = stringifyArray([identifyTemplate($template, $identityPattern)]); };
	$actual = $EVAL_ERROR if $EVAL_ERROR;
	assertStringEquality($expected, $actual, $message) ? $successes++ : $failures++;
}

{
	my $message = "identifyTemplate: if provided template containing one identity declaration alone on the last line, returns expected identity and template";
	my $template = "this is the first line\nthis is the middle line\nthis is the IDENTITY(\"zoidberg\") line";
	my $expected = "[ \"this is the first line\nthis is the middle line\nthis is the  line\", \"zoidberg\" ]";
	my $actual;
	eval { $actual = stringifyArray([identifyTemplate($template, $identityPattern)]); };
	$actual = $EVAL_ERROR if $EVAL_ERROR;
	assertStringEquality($expected, $actual, $message) ? $successes++ : $failures++;
}

{
	my $message = "identifyTemplate: if provided template containing one identity declaration with company on the first line, returns expected identity and template";
	my $template = "today is a IDENTITY(\"zoidberg\") reference kind of day";
	my $expected = "[ \"today is a  reference kind of day\", \"zoidberg\" ]";
	my $actual;
	eval { $actual = stringifyArray([identifyTemplate($template, $identityPattern)]); };
	$actual = $EVAL_ERROR if $EVAL_ERROR;
	assertStringEquality($expected, $actual, $message) ? $successes++ : $failures++;
}

{
	my $message = "identifyTemplate: if provided template containing one identity declaration with company on the middle line, returns expected identity and template";
	my $template = "this is the first line\nthis is the IDENTITY(\"zoidberg\") line\nthis is the last line";
	my $expected = "[ \"this is the first line\nthis is the  line\nthis is the last line\", \"zoidberg\" ]";
	my $actual;
	eval { $actual = stringifyArray([identifyTemplate($template, $identityPattern)]); };
	$actual = $EVAL_ERROR if $EVAL_ERROR;
	assertStringEquality($expected, $actual, $message) ? $successes++ : $failures++;
}

{
	my $message = "identifyTemplate: if provided template with no identity declaration, throws expected exception";
	my $template = "What a fine court, too, that requires such an explanation!";
	my $expected = "ERROR: No identity declaration found in template.\n";
	my $actual;
	eval { $actual = stringifyArray([identifyTemplate($template, $identityPattern)]); };
	$actual = $EVAL_ERROR if $EVAL_ERROR;
	assertStringEquality($expected, $actual, $message) ? $successes++ : $failures++;
}

{
	my $message = "identifyTemplate: if provided template with two identity declarations, throws expected exception";
	my $template = "Who else, but IDENTITY(\"zoidberg\"), and his sidekick IDENTITY(\"boy-dberg\")";
	my $expected = "ERROR: More than one identity declaration found in template first identified as \"boy-dberg\"\n";
	my $actual;
	eval { $actual = stringifyArray([identifyTemplate($template, $identityPattern)]); };
	$actual = $EVAL_ERROR if $EVAL_ERROR;
	assertStringEquality($expected, $actual, $message) ? $successes++ : $failures++;
}

{
	my $message = "identifyTemplate: if provided an empty template, throws expected exception";
	my $template = "";
	my $expected = "ERROR: No identity declaration found in template.\n";
	my $actual;
	eval { $actual = stringifyArray([identifyTemplate($template, $identityPattern)]); };
	$actual = $EVAL_ERROR if $EVAL_ERROR;
	assertStringEquality($expected, $actual, $message) ? $successes++ : $failures++;
}

print("\n");

#identifyTemplates tests
{
	my $message = "identifyTemplates: if provided a list of templates each with an identity declaration, returns expected templates hash";
	my @templates = ( "IDENTITY(\"zoidberg\")",
					  "I am IDENTITY(\"red_crab_man\")",
					  "I\nenjoy\nIDENTITY(\"crab\")\nmeat",
					  "Mr.\nIDENTITY(\"Krabs\")\nloves\nmoney");
	my $expected = "{ \"Krabs\" => \"Mr.\nloves\nmoney\", \"crab\" => \"I\nenjoy\nmeat\", \"red_crab_man\" => \"I am \", \"zoidberg\" => \"\" }";
	my $actual;
	eval { $actual = stringifyHash(identifyTemplates(\@templates, $identityPattern)); };
	$actual = $EVAL_ERROR if $EVAL_ERROR;
	assertStringEquality($expected, $actual, $message) ? $successes++ : $failures++;
}

{
	my $message = "identifyTemplates: if provided a list of templates in which one is missing an identity declaration, throws expected exception";
	my @templates = ( "IDENTITY(\"iceberg\")",
					  "I think I should go back to grad school soon.\nI would have to start studying for the GRE pretty soon too...",
					  "Why can't someone just pay me to do what I want? IDENTITY(\"identity\")");
	my $expected = "ERROR: No identity declaration found in template.\n";
	my $actual;
	eval { $actual = stringifyHash(identifyTemplates(\@templates, $identityPattern)); };
	$actual = $EVAL_ERROR if $EVAL_ERROR;
	assertStringEquality($expected, $actual, $message) ? $successes++ : $failures++;
}

{
	my $message = "identifyTemplates: if provided a valid list of templates, the original list is not modified";
	my @templates = ( "test1 IDENTITY(\"test1\")",
					  "test2 IDENTITY(\"test2\")",
					  "testE IDENTITY(\"teste\")");
	my $expected = "[ \"test1 IDENTITY(\"test1\")\", \"test2 IDENTITY(\"test2\")\", \"testE IDENTITY(\"teste\")\" ]";
	my $actual;
	eval { identifyTemplates(\@templates, $identityPattern); $actual = stringifyArray(\@templates); };
	$actual = $EVAL_ERROR if $EVAL_ERROR;
	assertStringEquality($expected, $actual, $message) ? $successes++ : $failures++;
}

{
	my $message = "identifyTemplates: if provided a list of templates with repeated identities, throws the expected exception";
	my @templates = ( "\n\n\n\n\n\nIDENTITY(\"zoidberg\")\n\n\n",
					  "zoidberg\nIDENTITY(\"sheldon\")\niceberg\n",
					  "IDENTITY(\"zoidberg\")");
	my $expected = "ERROR: More than one template identified as \"zoidberg\"\n";
	my $actual;
	eval { $actual = stringifyHash(identifyTemplates(\@templates, $identityPattern)); };
	$actual = $EVAL_ERROR if $EVAL_ERROR;
	assertStringEquality($expected, $actual, $message) ? $successes++ : $failures++;
}

# TODO: check for repeat identities, make sure $template declared in foreach isn't modified, reconsider having a %templates hash AND a @templates array

# TODO: how the FUCK do I abstract the three common $actual lines?


# final results printout
print("\nFINISHED\n");
print("    SUCCESSES - " . $successes . "\n");
print("    FAILURES - " . $failures . "\n");
