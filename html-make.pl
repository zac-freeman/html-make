#!/usr/bin/perl
use strict;
use warnings;

my $dir;
my $path = $ARGV[0];
opendir($dir, $path);

#stores file names with file content from files in $dir into %files
my %files;
while (my $file = readdir($dir)) {
	my $filePath = "$path/$file";
	if (-f $filePath) {
		open(my $handle, $filePath);
		my $content = <$handle>;
		close($handle);

		chomp $content;
		$files{$file} = $content;
	}
}

closedir($dir);

#prints contents of %files
while ((my $file, my $content) = each(%files)) {
	print("$file: $content\n");
}
