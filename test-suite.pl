#!/usr/bin/perl
use strict;
use warnings;
use English;

eval { require "./html-make.pl"; };

# test metrics
my $successes = 0;
my $failures = 0;

# reusable variables
my $dependencyPattern = qr/DEPENDENCY\(\"([0-9a-zA-Z._\-]+)\"\)/;
my $locationPattern = qr/LOCATION\(\"([0-9a-zA-Z._\-\/]+)\"\)/;
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

# sorts array then maps array to a string representation
sub stringifyArray {
	my @array = @{$_[0]};

	return "[ " . join(", ", map { "\"$ARG\"" } sort {$a cmp $b} @array) . " ]";
}

# stringifies each hash in the array, then stringifies the array
sub stringifyArrayOfHashes {
	my @array = @{$_[0]};

	return stringifyArray([map { stringifyHash($ARG) } @array]);
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

# extractPattern tests
{

	my $message = "extractPattern: if provided template containing one identity declaration that is alone on the first line, returns expected identity and template";
	my $template = "IDENTITY(\"bazinga\")\nThe whole universe was in a hot dense state...";
	my $expected = "[ \"The whole universe was in a hot dense state...\", \"bazinga\" ]";
	my $actual;
	eval { $actual = stringifyArray([extractPattern($template, $identityPattern, 1)]); };
	$actual = $EVAL_ERROR if $EVAL_ERROR;
	assertStringEquality($expected, $actual, $message) ? $successes++ : $failures++;
}

{
	my $message = "extractPattern: if provided template containing one identity declaration alone on the middle line, returns expected identity and template";
	my $template = "this is the first line\nIDENTITY(\"middle\")\nthis is the last line";
	my $expected = "[ \"middle\", \"this is the first line\nthis is the last line\" ]";
	my $actual;
	eval { $actual = stringifyArray([extractPattern($template, $identityPattern, 1)]); };
	$actual = $EVAL_ERROR if $EVAL_ERROR;
	assertStringEquality($expected, $actual, $message) ? $successes++ : $failures++;
}

{
	my $message = "extractPattern: if provided template containing one identity declaration alone on the last line, returns expected identity and template";
	my $template = "this is the first line\nthis is the middle line\nIDENTITY(\"zoidberg\")";
	my $expected = "[ \"this is the first line\nthis is the middle line\", \"zoidberg\" ]";
	my $actual;
	eval { $actual = stringifyArray([extractPattern($template, $identityPattern, 1)]); };
	$actual = $EVAL_ERROR if $EVAL_ERROR;
	assertStringEquality($expected, $actual, $message) ? $successes++ : $failures++;
}

{
	my $message = "extractPattern: if provided template containing one identity declaration with company on the first line, returns expected identity and template";
	my $template = "today is a IDENTITY(\"zoidberg\") reference kind of day";
	my $expected = "[ \"today is a  reference kind of day\", \"zoidberg\" ]";
	my $actual;
	eval { $actual = stringifyArray([extractPattern($template, $identityPattern, 1)]); };
	$actual = $EVAL_ERROR if $EVAL_ERROR;
	assertStringEquality($expected, $actual, $message) ? $successes++ : $failures++;
}

{
	my $message = "extractPattern: if provided template containing one identity declaration with company on the middle line, returns expected identity and template";
	my $template = "this is the first line\nthis is the IDENTITY(\"zoidberg\") line\nthis is the last line";
	my $expected = "[ \"this is the first line\nthis is the  line\nthis is the last line\", \"zoidberg\" ]";
	my $actual;
	eval { $actual = stringifyArray([extractPattern($template, $identityPattern, 1)]); };
	$actual = $EVAL_ERROR if $EVAL_ERROR;
	assertStringEquality($expected, $actual, $message) ? $successes++ : $failures++;
}

{
	my $message = "extractPattern: if provided template with no identity declaration, throws expected exception";
	my $template = "What a fine court, too, that requires such an explanation!";
	my $expected = "ERROR: No instance of pattern \"(?^:IDENTITY\\(\\\"([0-9a-zA-Z._\\-]+)\\\"\\))\" found in template.\n";
	my $actual;
	eval { $actual = stringifyArray([extractPattern($template, $identityPattern, 1)]); };
	$actual = $EVAL_ERROR if $EVAL_ERROR;
	assertStringEquality($expected, $actual, $message) ? $successes++ : $failures++;
}

{
	my $message = "extractPattern: if provided template with two identity declarations, throws expected exception";
	my $template = "Who else, but IDENTITY(\"zoidberg\"), and his sidekick IDENTITY(\"boy-dberg\")";
	my $expected = "ERROR: More than one instance of pattern \"(?^:IDENTITY\\(\\\"([0-9a-zA-Z._\\-]+)\\\"\\))\" found in template with first catch \"zoidberg\"\n";
	my $actual;
	eval { $actual = stringifyArray([extractPattern($template, $identityPattern, 1)]); };
	$actual = $EVAL_ERROR if $EVAL_ERROR;
	assertStringEquality($expected, $actual, $message) ? $successes++ : $failures++;
}

{
	my $message = "extractPattern: if provided an empty template, throws expected exception";
	my $template = "";
	my $expected = "ERROR: No instance of pattern \"(?^:IDENTITY\\(\\\"([0-9a-zA-Z._\\-]+)\\\"\\))\" found in template.\n";
	my $actual;
	eval { $actual = stringifyArray([extractPattern($template, $identityPattern, 1)]); };
	$actual = $EVAL_ERROR if $EVAL_ERROR;
	assertStringEquality($expected, $actual, $message) ? $successes++ : $failures++;
}

{
	my $message = "extractPattern: if provided a template with no location declaration when it isn't required, returns expected location and template";
	my $template = "this can be anything it wants\n\n\n";
	my $expected = "[ \"\", \"this can be anything it wants\n\n\n\" ]";
	my $actual;
	eval { $actual = stringifyArray([extractPattern($template, $locationPattern, 0)]); };
	$actual = $EVAL_ERROR if $EVAL_ERROR;
	assertStringEquality($expected, $actual, $message) ? $successes++ : $failures++;
}

{
	my $message = "extractPattern: if provided a template with a location declaration when it isn't required, returns expected location and template";
	my $template = "wants\nneeds\ndesires\nLOCATION(\"top\")";
	my $expected = "[ \"top\", \"wants\nneeds\ndesires\" ]";
	my $actual;
	eval { $actual = stringifyArray([extractPattern($template, $locationPattern, 0)]); };
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
	my $expected = "ERROR: No instance of pattern \"(?^:IDENTITY\\(\\\"([0-9a-zA-Z._\\-]+)\\\"\\))\" found in template.\n";
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

print("\n");

# locateTemplates tests
{
	my $message = "locateTemplates: if provided a valid templates hash, returns the expected identityToLocation hash and templates hash";
	my %templates = ( "zoID" => "now back to our regularly scheduled programming LOCATION(\"zoidberg\")",
					  "lipID" => "the location of this one is \"lip\"LOCATION(\"lip\")");
	my $expected = "[ \"{ \"lipID\" => \"lip\", \"zoID\" => \"zoidberg\" }\", \"{ \"lipID\" => \"the location of this one is \"lip\"\", \"zoID\" => \"now back to our regularly scheduled programming \" }\" ]";
	my $actual;
	eval { $actual = stringifyArrayOfHashes([locateTemplates(\%templates, $locationPattern)]); };
	$actual = $EVAL_ERROR if $EVAL_ERROR;
	assertStringEquality($expected, $actual, $message) ? $successes++ : $failures++;
}

{
	my $message = "locateTemplates: if provided a valid templates hash with locations containing forward slashes, returns the expected identityToLocation hash and templates hash";
	my %templates = ( "future" => "oh god I hope this works...LOCATION(\"futurama/zoidberg\")",
					  "present" => "the location of this one is \"present/crabman\"LOCATION(\"present/crabman\")");
	my $expected = "[ \"{ \"future\" => \"futurama/zoidberg\", \"present\" => \"present/crabman\" }\", \"{ \"future\" => \"oh god I hope this works...\", \"present\" => \"the location of this one is \"present/crabman\"\" }\" ]";
	my $actual;
	eval { $actual = stringifyArrayOfHashes([locateTemplates(\%templates, $locationPattern)]); };
	$actual = $EVAL_ERROR if $EVAL_ERROR;
	assertStringEquality($expected, $actual, $message) ? $successes++ : $failures++;
}

{
	my $message = "locateTemplates: if provided a valid templates hash containing no location declarations, returns the expected identityToLocation hash and templates hash";
	my %templates = ( "noLocationOne" => "this corresponds to identity noLocationOne",
					  "noLocationTwo" => "this corresponds to zoidberg!");
	my $expected = "[ \"{  }\", \"{ \"noLocationOne\" => \"this corresponds to identity noLocationOne\", \"noLocationTwo\" => \"this corresponds to zoidberg!\" }\" ]";
	my $actual;
	eval { $actual = stringifyArrayOfHashes([locateTemplates(\%templates, $locationPattern)]); };
	$actual = $EVAL_ERROR if $EVAL_ERROR;
	assertStringEquality($expected, $actual, $message) ? $successes++ : $failures++;
}

{
	my $message = "locateTemplates: if provided a templates hash with a repeated location declaration, throws the expected exception";
	my %templates = ( "truth" => "all is LOCATION(\"zoidberg\")",
					  "wisdom" => "praise be to LOCATION(\"zoidberg\")",
					  "justInCase" => "this is here just to mix it up, test-wise LOCATION(\"test\")");
	my $expected = "ERROR: More than one template located at \"zoidberg\": ";
	my $actual;
	eval { $actual = stringifyArrayOfHashes([locateTemplates(\%templates, $locationPattern)]); };
	$actual = $EVAL_ERROR if $EVAL_ERROR;
	assertStringEquality($expected, substr($actual, 0, 53), $message) ? $successes++ : $failures++;
}

print("\n");

# joinOnIdentities tests
{
	my $message = "joinOnIdentities: if provided two valid hashes, each with one entry for the same identity, returns expected locationToTemplate hash";
	my %identityToLocation = ( "zoidberg" => "futurama/3005/test" );
	my %identityToTemplate = ( "zoidberg" => "who else but crabman" );
	my $expected = "{ \"futurama/3005/test\" => \"who else but crabman\" }";
	my $actual;
	eval { $actual = stringifyHash(joinOnIdentities(\%identityToLocation, \%identityToTemplate)); };
	$actual = $EVAL_ERROR if $EVAL_ERROR;
	assertStringEquality($expected, $actual, $message) ? $successes++ : $failures++;
}

{
	my $message = "joinOnIdentities: if provided two valid hashes that do not have a location for each identity, returns expected locationToTemplate hash";
	my %identityToLocation = ( "zoidberg" => "futurama/3005/test",
							   "bazinga" => "big/bang/theory");
	my %identityToTemplate = ( "zoidberg" => "who else but crabman",
							   "bazinga" => "sheldon cooper\n seldom pooper",
							   "component" => "templates without locations can be used as dedicated components");
	my $expected = "{ \"big/bang/theory\" => \"sheldon cooper\n seldom pooper\", \"futurama/3005/test\" => \"who else but crabman\" }";
	my $actual;
	eval { $actual = stringifyHash(joinOnIdentities(\%identityToLocation, \%identityToTemplate)); };
	$actual = $EVAL_ERROR if $EVAL_ERROR;
	assertStringEquality($expected, $actual, $message) ? $successes++ : $failures++;
}

{
	my $message = "joinOnIdentities: if provided two valid hashes that do not have a template for each identity, throws expected exception";
	my %identityToLocation = ( "zoidberg" => "remember that weird mating ritual episode?",
							   "doctor" => "I/hardly/know/her!",
							   "doctor_doctor" => "give me the news");
	my %identityToTemplate = ( "zoidberg" => "who else but the red crab doctor",
							   "doctor_doctor" => "I got a bad case of lovin' you!");
	my $expected = "ERROR: No template found with identity \"doctor\" and location \"I/hardly/know/her!\"\n";
	my $actual;
	eval { $actual = stringifyHash(joinOnIdentities(\%identityToLocation, \%identityToTemplate)); };
	$actual = $EVAL_ERROR if $EVAL_ERROR;
	assertStringEquality($expected, $actual, $message) ? $successes++ : $failures++;
}

print("\n");

# processTemplates tests
{
	my $message = "processTemplates: if provided a list of identified, located templates with no dependencies, returns expected locationToTemplate hash";
	my @templates = ( "IDENTITY(\"identityOne\")\nLOCATION(\"locationOne\")\ncontentOne",
					  "contentTwo\nLOCATION(\"locationTwo\")\nIDENTITY(\"identityTwo\")",
					  "LOCATION(\"locationThree\")IDENTITY(\"identityThree\")contentThree");
	my $cycleCheckEnabled = 1;
	my $expected = "{ \"locationOne\" => \"contentOne\", \"locationThree\" => \"contentThree\", \"locationTwo\" => \"contentTwo\" }";
	my $actual;
	eval { $actual = stringifyHash(processTemplates(\@templates, $identityPattern, $locationPattern, $dependencyPattern, $cycleCheckEnabled)); };
	$actual = $EVAL_ERROR if $EVAL_ERROR;
	assertStringEquality($expected, $actual, $message) ? $successes++ : $failures++;
}

{
	my $message = "processTemplates: if provided a list of identified, located templates with dependencies, returns expected locationToTemplate hash";
	my @templates = ( "MY CHILD:\nDEPENDENCY(\"child\")\nIDENTITY(\"parent\")\nLOCATION(\"parent\")",
					  "MY CHILD:\nDEPENDENCY(\"grandchild\")\nIDENTITY(\"child\")\nLOCATION(\"child\")",
					  "IDENTITY(\"grandchild\")\nI AM THE GRANDCHILD");
	my $cycleCheckEnabled = 1;
	my $expected = "{ \"child\" => \"MY CHILD:\nI AM THE GRANDCHILD\", \"parent\" => \"MY CHILD:\nMY CHILD:\nI AM THE GRANDCHILD\" }";
	my $actual;
	eval { $actual = stringifyHash(processTemplates(\@templates, $identityPattern, $locationPattern, $dependencyPattern, $cycleCheckEnabled)); };
	$actual = $EVAL_ERROR if $EVAL_ERROR;
	assertStringEquality($expected, $actual, $message) ? $successes++ : $failures++;
}

print("\n");

#filterFiles tests
# TODO

# final results printout
print("\nFINISHED\n");
print("    SUCCESSES - " . $successes . "\n");
print("    FAILURES - " . $failures . "\n");
