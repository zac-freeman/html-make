#!/usr/bin/perl
use strict;
use warnings;

#for a file at a given path, returns its content
sub getFileContent {
	my $path = $_[0];

	open(my $handle, $path);
	my $content = "";
	while (my $line = <$handle>) {
		$content = "$content$line";
	}

	chomp($content);
	close($handle);
	return $content
}

#for a folder at a given path, returns a map of file names to file contents
sub getFolderContent {
	my $path = $_[0];

	my $dir;
	opendir($dir, $path);

	my %files;
	while (my $file = readdir($dir)) {
		my $filePath = "$path/$file";
		
		#if it is a file, check if the file name is unique,
		#if it is unique, grab its content and store it in the map
		#if it isn't unique, throw an error about a file name collision
		if (-f $filePath) {
			if (exists($files{$file})) {
				die("ERROR: Found multiple files with name \"$file\"\n");
			}
			my $content = getContent($filePath);
			$files{$file} = $content;
		}
		#if it is a directory other than the relative directories (., ..),
		#get the files from it and store them in the map
		elsif (-d $filePath and $file ne "." and $file ne ".." ) {
			my %grandfiles = getFiles($filePath);
			%files = (%files, %grandfiles);
		}
	}

	closedir($dir);
	return %files;
}

#for a given file content and a given map reference, finds instances of [[*]],
#replaces it with the corresponding file content, and returns the updated file content
sub findAndReplace {
	my $content = $_[0];
	my $files = $_[1];

	while ($content =~ /\[\[[0-9a-zA-Z._\-]+\]\]/) {
		my $start = $-[0];
		my $end = $+[0];
		my $file = substr($content, $start + 2, $end - $start - 4);
		if (!exists($files->{$file})) {
			die("ERROR: No file found with name \"$file\"\n");
		}
		$files->{$file} = findAndReplace($files->{$file}, $files);
		$content = substr($content, 0, $start) . $files->{$file} . substr($content, $end);
	}
	return $content;
}


my $path = $ARGV[0];
my %files = getFiles($path);

findAndReplace("[[template.html]]", \%files);

while((my $file, my $content) = each(%files)) {
	print("\n--------\n$file:\n$content\n");
}

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
my $dependencyPattern = "DEPENDENCY\(([0-9a-zA-Z._\-]+)\)";

# TODO
my $identityPattern = "";

# TODO
my $locationPattern = "";

sub populateTemplates {}

# TODO: write tests this beautiful beast
# find instances of the given dependencyPattern within the given template and replace each of the found instances
# with the contents corresponding to the instance's dependencyName in the given templates hash
sub populateTemplate {
	my $template = $_[0];			# contents of a template
	my $templates = $_[1];			# REFERENCE to a hash corresponding template names to template contents
	my $dependencyPattern = $_[2];	# regex to capture dependencies declared in the template
	my @parents = @{$_[3]}; 		# chronological array of names of templates being populated, ignored if empty

	while ($template =~ /$dependencyPattern/) {
		my $start = $-[0];
		my $end = $+[0];
		my $dependencyName = $1;

		# throw an error if dependencyName is already present in parents array
		if (grep(/^$dependencyName$/, @parents)) {
			die("ERROR: Repeat found in " . join(" -> ", @parents) . " -> " . $dependencyName . "\n");
		}

		# if the parents array is empty, add dependencyName to the end of it
		if (@parents != 0) {
			push (@parents, $dependencyName);
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
