#!/usr/bin/perl
use strict;
use warnings;

#for a file at a given path, returns its content
sub getContent {
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

#for files at a given path, returns a map of file names to file contents
sub getFiles {
	my $path = $_[0];

	my $dir;
	opendir($dir, $path);

	my %files;
	while (my $file = readdir($dir)) {
		$file = "$path/$file";
		
		#if it is a file, grab its content and store it in the map
		if (-f $file) {
			my $content = getContent($file);
			$files{$file} = $content;
		}
		#if it is a directory, get the files from it and store them in the map
		elsif (-d $file and $file ne "$path/." and $file ne"$path/.." ) {
			#closedir($dir); ?
			my %grandfiles = getFiles($file);
			%files = (%files, %grandfiles);
			#opendir($dir, $path); ?
		}
	}

	closedir($dir);
	return %files;
}

#in a given file content, finds instances of [[*]] and replaces it with corresponding file content
sub findAndReplace {
	my $content = $_[0];

	while ($content =~ /\[\[[0-9a-zA-Z._\-]+\]\]/) {
		$content = substr($content, 0, $-[0]) . "-FOUND-" . substr($content, $+[0]);
	}
	print("$content\n");
}

findAndReplace("bazinga shakira [[template.html]] sixteen [[thirty3.html]]");

my $path = $ARGV[0];
my %files = getFiles($path);

#prints contents of %files
while ((my $file, my $content) = each(%files)) {
	print("--------\n$file\n--------\n$content\n");
}
