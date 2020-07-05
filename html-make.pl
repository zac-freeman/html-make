#!/usr/bin/perl
use strict;
use warnings;

# matches IDENTITY("IDENTITY_NAME") and captures IDENTITY_NAME into $1
my $identityPattern = qr/IDENTITY\(\"([0-9a-zA-Z._\-]+)\"\)/;

# matches LOCATION("LOCATION_NAME") and captures LOCATION_NAME into $1
my $locationPattern = qr/LOCATION\(\"([0-9a-zA-Z._\-\/]+)\"\)/;

# matches DEPENDENCY("DEPENDENCY_NAME") and captures DEPENDENCY_NAME into $1
my $dependencyPattern = qr/DEPENDENCY\(\"([0-9a-zA-Z._\-]+)\"\)/;

# TODO: CLI

# writes the contents to the corresponding location for each entry in the given hash 
sub writeFiles {
	my %locationToContent = %{$_[0]};

	foreach my $location (keys %locationToContent) {
		writeFile($location, $locationToContent{$location});
	}
}

# writes the given content into a file created at the given location
sub writeFile {
	my $location = $_[0];
	my $content = $_[1];

	# gets the list of directories in the path to the file location
	# and creates each one that does not already exist
	my @directories = splice(@{[split(/\//, $location)]}, 0, -1);
	my $path = "";
	foreach my $directory (@directories) {
		$path = $path . $directory . "/";
		if (!-e $path) {
			mkdir($path);
		}
	}

	# open or create file to write to, throw an error if unable to read
	open(my $handle, ">", $location)
		or die("ERROR: Unable to create or open file at \"" . $location . "\"\n");

	print $handle $content;

	close($handle)
		or die("ERROR: Unable to close file at \"" . $location . "\"\n"); 
}

# reads all files within a given location, then returns their contents as an array of strings
sub readFiles {
	my $location = $_[0];

	# if there is a regular file at the location, return its contents
	if (-f $location) {
		return [readFile($location)];
	}

	# get the list of file names in the directory at the given location
	my @files = @{readDirectory($location)};

	# for each file in the directory (excluding . and ..),
	# read its content(s) and add it to contents
	my @contents;
	foreach my $file (grep {$_ ne "." && $_ ne ".."} @files) {
		push(@contents, @{readFiles($location . "/" . $file)});
	}

	return \@contents;
}

# reads a file at a given location, then returns the content as a string
sub readFile {
	my $location = $_[0];

	# open the file to read, throw an error if unable to read
	open(my $handle, "<", $location)
		or die("ERROR: Unable to read file at \"" . $location . "\"\n");

	# read the file into content
	my $content = "";
	while (my $line = <$handle>) {
		$content = $content . $line;
	}

	# close the file, throw an error if unable to close
	close($handle)
		or die("ERROR: Unable to close file at \"" . $location . "\"\n");

	return $content;
}

# reads all the file names in the directory at the given location,
# then returns them as an array of strings
sub readDirectory {
	my $location = $_[0];

	# open the directory, throw an error if unable to open
	opendir(my $directory, $location)
		or die("ERROR: Unable to open directory at \"" . $location . "\"\n");

	# get the list of file names in the directory
	my @files = readdir($directory);

	# close the directory, throw an error if unable to close
	closedir($directory)
		or die("ERROR: Unable to close directory at \"" . $location . "\"\n");

	return \@files;
}

# identifies, locates, and populates a given array of templates using the given patterns, then
# returns a hash corresponding locations to templates
sub processTemplates {
	my @templates = @{$_[0]};		# array of template contents
	my $indentityPattern = $_[1];	# regex to capture identities declared in templates
	my $locationPattern = $_[2];	# regex to capture locations declared in templates
	my $dependencyPattern = $_[3];	# regex to capture dependencies declared in templates
	my $cycleCheckEnabled = $_[4];	# boolean to enable cyclic depedency checking

	my $templates;			# REFERENCE to a hash of identities to templates
	my $identityToLocation; # REFERENCE to a hash of identities to locations
	$templates = identifyTemplates(\@templates, $identityPattern);
	($identityToLocation, $templates) = locateTemplates($templates, $locationPattern);
	$templates = populateTemplates($templates, $dependencyPattern, $cycleCheckEnabled);
	return joinOnIdentities($identityToLocation, $templates);
}

# joins the given identityToLocation hash and identityToTemplate hash on their keys, then returns a
# hash corresponding locations to templates
sub joinOnIdentities {
	my %identityToLocation = %{$_[0]};	# hash corresponding identities to locations
	my %identityToTemplate = %{$_[1]};	# hash corresponding identities to templates

	my %locationToTemplate;
	foreach my $identity (keys %identityToLocation) {
		my $location = $identityToLocation{$identity};
		my $template = $identityToTemplate{$identity};

		# throw an error if there is an identity key in identityToLocation that is not in identityToTemplate
		if (!defined($template)) {
			die("ERROR: No template found with identity \"" . $identity . "\" and location \"" . $location . "\"\n");
		}

		$locationToTemplate{$location} = $template;
	}

	return \%locationToTemplate;
}

# invokes extractPattern(), with identityPattern, once for each template in the given templates
# array, then returns the templates hash associating identities to template contents
sub identifyTemplates {
	my @templates = @{$_[0]};	 # array containing template contents
	my $identityPattern = $_[1]; # regex to capture identities declared in templates

	my %templates;
	foreach my $template (@templates) {
		(my $identity, $template) = extractPattern($template, $identityPattern, 1);

		# throw an error if more than one template have the same identity
		if (defined($templates{$identity})) {
			die("ERROR: More than one template identified as \"" . $identity . "\"\n");
		}

		$templates{$identity} = $template;
	}

	return \%templates;
}

# invokes extractPattern(), with locationPattern, once for each template in the given templates
# hash, corresponds each template identity to a location, then returns the hash corresponding
# identities to locations and the hash corresponding identities to templates
# NOTE: a template is not required to have a location
sub locateTemplates {
	my %templates = %{$_[0]};	 # hash corresponding identities to templates
	my $locationPattern = $_[1]; # regex to capture locations declared in templates

	my %locationToIdentity;
	foreach my $identity (keys %templates) {
		(my $location, my $template) = extractPattern($templates{$identity}, $locationPattern, 0);

		# throw an error if more than one template have the same location
		if (defined($locationToIdentity{$location})) {
			die("ERROR: More than one template located at \"" . $location . "\": \"" .
				$identity . "\" and \"" . $locationToIdentity{$location} . "\"\n");
		}

		# exclude templates with no location declared from the locationToIdentity hash
		if ($location ne "") {
			$locationToIdentity{$location} = $identity;
		}

		$templates{$identity} = $template;
	}

	my %identityToLocation = reverse %locationToIdentity;
	return (\%identityToLocation, \%templates);
}

# finds an instance of the given pattern within the given template, then returns the captured
# value and the template absent the found instance of the pattern
sub extractPattern {
	my $template = $_[0];	# contents of a template
	my $pattern = $_[1];	# regex to find a pattern and capture a value
	my $required = $_[2];	# boolean to require at least one instance of pattern

	my $catch = "";
	my $instances = 0;
	while ($template =~ $pattern) {
		# throw error if more than one instances of the pattern is found
		$instances++;
		if ($instances > 1) {
			die ("ERROR: More than one instance of pattern \"". $pattern .
				 "\" found in template with first catch \"". $catch ."\"\n");
		}

		# capture start, end, and captured value of pattern match
		my $start = $-[0];
		my $end = $+[0];
		$catch = $1;

		# if the pattern match is alone on the line, remove at most one of the surrounding
		# newlines
		if (($start == 0 || substr($template, $start - 1, 1) eq "\n") &&
			($end == length($template) || substr($template, $end, 1) eq "\n")) {
			if ($start > 0) {
				$start--;
			} elsif ($end < length($template) - 1) {
				$end++;
			}
		}

		# remove the pattern match from the template
		$template = substr($template, 0, $start) . substr($template, $end);
	}

	# throw an error if less than one instance the pattern is found and one is required
	if ($instances < 1 && $required) {
		die("ERROR: No instance of pattern \"" . $pattern . "\" found in template.\n");
	}

	return ($catch, $template);
}

# invokes populateTemplate() once for each template in the given templates hash, then returns the
# populated templates hash
sub populateTemplates {
	my %templates = %{$_[0]};		# hash corresponding template names to template contents
	my $dependencyPattern = $_[1];	# regex to capture dependencies declared in the templates
	my $cycleCheckEnabled = $_[2];	# boolean to enable cyclic dependency checking

	foreach my $name (keys %templates) {
		my @parents = $cycleCheckEnabled ? ($name) : ();
		$templates{$name} = populateTemplate($templates{$name}, \%templates, $dependencyPattern, \@parents);
	}

	return \%templates;
}

# finds instances of the given dependencyPattern within the given template and replaces each of the
# found instances with the contents corresponding to the instance's dependencyName in the given
# templates hash, thens return the populated template
sub populateTemplate {
	my $template = $_[0];			# contents of a template
	my $templates = $_[1];			# REFERENCE to a hash of template names to template contents
	my $dependencyPattern = $_[2];	# regex to capture dependencies declared in the template
	my @parents = @{$_[3]}; 		# ordered list of dependent templates, ignored if empty

	while ($template =~ $dependencyPattern) {
		# get the start position, end position, and captured name of the regex match
		my $start = $-[0];
		my $end = $+[0];
		my $dependencyName = $1;

		# throw an error if dependencyName is already present in parents array
		if (grep(/^$dependencyName$/, @parents)) {
			die("ERROR: Cyclic dependency found in " . join(" -> ", @parents) . " -> " .
				$dependencyName . "\n");
		}

		# if the parents array isn't empty, add dependencyName to the end of it
		if (@parents != 0) {
			push(@parents, $dependencyName);
		}

		# get a reference to the contents corresponding to the dependencyName,
		# throw an error if the contents aren't present in the templates hash
		my $dependency = \$templates->{$dependencyName};
		if (!defined($$dependency)) {
			die("ERROR: No template found in templates hash with name \"" .
				$dependencyName . "\"\n");
		}

		# populate the dependency contents, then insert it in place of the dependency declaration
		$$dependency = populateTemplate($$dependency, $templates, $dependencyPattern, \@parents);
		$template = substr($template, 0, $start) . $$dependency . substr($template, $end);
	}

	return $template;
}
