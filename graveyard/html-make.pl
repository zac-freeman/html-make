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
