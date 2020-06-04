#!/usr/bin/perl
use strict;
use warnings;

# new function organization:
#
#	Keep IO and non-IO functions seperate (haskell, eat your heart out) for testing purposes. I think
#	IO functions can be represented by "file access" functions and non-IO functions can be represented
#	by "map manipulation" functions.
#
#	The purpose is to enable unit testing before moving forward with more complicated development.
#	Also it might enable replacing the file access functions with ones specific to the other
#	operating systems.
#
#	The file access code should remain relatively constant. The map manipulation code should be unit
#	tested heavily. The useful functionality of this project will exist at the intersection of the IO
#	and non-IO code. This intersection should be as small as possible
#
#	The complete separation of the two types of functions should be supported by the names of variables
#	and functions as much as possible.
#
#	Parsing functions/syntax defintions are an additional non-IO component of the project. These can
#	be unit tested and made replaceable.
#
#   file access functions (IO):
#		getFileContent(String path) - gets the content of one file located at a given path
#		getFolderContent(String path) - gets the contents of the files (as a map) at a given
#										path (for each item at a given folderPath,
#										calls either getFileContent or getFolderContent)
#		writeFile(String path, String content) - writes the given content to a given path
#		writeFiles(Map files) - calls writeFile once for each key:value (path:content) entry
#								in the given files map
#
#	map manipulation functions (non-IO):
#		populateTemplate(String templates, Map templates) - populates a given template with content from a
#															given templates map (calls itself recursively
#															to populate unpopulated template dependencies
#															of the given template)
#		populateTemplates(Map templates) - calls populateTemplate once for each template in a given
#										   templates map
#		locateTemplates(Map templates) - generates a map from a templates map that associates the final
#										 filePath with the final fileContent
#		identifyTemplates(Map templates) - generates a hash corresponding template names to template
#										   contents
#
#	syntax definitions:
#		String locationPattern - regex that identifies the final path for the template after
#								 population has been completed, if this isn't present in a file,
#								 it won't be written anywhere, something like "LOCATION('FILE_PATH')"
#		String identityPattern - regex that identifies the name/title/identity of a file for use in
#								 the templates map, something like "IDENTITY('IDENTITY_NAME')"
#		String dependencyPattern - regex that identifies the pattern for dependencies in a template,
#								   something like "DEPENDENCY('DEPENDENCY_NAME')"
#		String urlPattern - determines if a given path is a url or not (not a url => filepath) (for later)
#
#	intersections:
#		processFiles(String path) - write(locate(populate(read(root_folder_path))))

# syntax consideration:
# 	Should be easy to understand and write. Should intersect with the syntax of other languages
#	(especially HTML and CSS)

# matches DEPENDENCY(DEPENDENCY_NAME) and captures DEPENDENCY_NAME into $1
my $dependencyPattern = qr/DEPENDENCY\(\"([0-9a-zA-Z._\-]+)\"\)/;

# TODO
my $identityPattern = qr/IDENTITY\(\"([0-9a-zA-Z._\-]+)\"\)/;

# TODO
my $locationPattern = "";

# find an instance of the given identityPattern within the given template, then return the captured
# name/identity and the template absent the line containing the found instance
sub identifyTemplate {
	my $template = $_[0];
	my $identityPattern = $_[1];

	my $identity;
	my $instances = 0;
	while ($template =~ $identityPattern) {
		my $start = $-[0];
		my $end = $+[0];
		$identity = $1;

		$instances++;
		if ($instances > 1) {
			die("ERROR: More than one identity declaration found in template first identified as \"" . $identity . "\"\n");
		}

		# TODO: figure out how to determine if the identity declaration is alone on the line
#		if (($start == 0 || substr($template, $start, 1) eq "\n") &&
#			($end == length($template) - 1 || substr($template, $end, 1) eq "\n")) {
#			
#		}

		# removes the identity declaration from the template
		$template = substr($template, 0, $start) . substr($template, $end);
	}

	if ($instances < 1) {
		die("ERROR: No identity declaration found in template.\n");
	}

	return [$identity, $template];
}

# invoke populateTemplate() once for each template in the given templates hash
sub populateTemplates {
	my %templates = %{$_[0]};		# hash corresponding template names to template contents
	my $dependencyPattern = $_[1];	# regex to capture dependencies declared in the templates
	my $cycleCheckEnabled = $_[2];	# boolean to enable checking for cyclic dependencies in templates hash

	foreach my $name (keys %templates) {
		my @parents = $cycleCheckEnabled ? ($name) : ();
		$templates{$name} = populateTemplate($templates{$name}, \%templates, $dependencyPattern, \@parents);
	}

	return \%templates;
}

# find instances of the given dependencyPattern within the given template and replace each of the
# found instances with the contents corresponding to the instance's dependencyName in the given
# templates hash
sub populateTemplate {
	my $template = $_[0];			# contents of a template
	my $templates = $_[1];			# REFERENCE to a hash corresponding template names to template contents
	my $dependencyPattern = $_[2];	# regex to capture dependencies declared in the template
	my @parents = @{$_[3]}; 		# chronological array of names of templates being populated, ignored if empty

	while ($template =~ $dependencyPattern) {
		# get the start position, end position, and captured name of the regex match
		my $start = $-[0];
		my $end = $+[0];
		my $dependencyName = $1;

		# throw an error if dependencyName is already present in parents array
		if (grep(/^$dependencyName$/, @parents)) {
			die("ERROR: Cyclic dependency found in " . join(" -> ", @parents) . " -> " . $dependencyName . "\n");
		}

		# if the parents array isn't empty, add dependencyName to the end of it
		if (@parents != 0) {
			push(@parents, $dependencyName);
		}

		# get a reference to the contents corresponding to the dependencyName,
		# throw an error if the contents aren't present in the templates hash
		my $dependency = \$templates->{$dependencyName};
		if (!defined($$dependency)) {
			die("ERROR: No template found in templates hash with name \"" . $dependencyName . "\"\n");
		}

		# populate the dependency contents, then insert it in the place of the dependency declaration
		$$dependency = populateTemplate($$dependency, $templates, $dependencyPattern, \@parents);
		$template = substr($template, 0, $start) . $$dependency . substr($template, $end);
	}

	return $template;
}

return 1; # to enable invoking this script with require
