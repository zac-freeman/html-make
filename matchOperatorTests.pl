$x = "<body><h1>test</h1> DEPENDENCY(DEPENDENCY_NAME) DEPENDENCY() </body>";

$x =~ /DEPENDENCY\(([0-9a-zA-Z._\-]+)\)/;

print "Start of match: $-[0]\n";
print "End of match: $+[0]\n";
print "Start of name: $-[1]\n";
print "End of name: $+[1]\n";
print "Name: $1\n";

$y = "DEPENDENCY(FIRST) DEPENDENCY(SECOND) DEPENDENCY(THIRD)";

while ($y =~ /DEPENDENCY\(([0-9a-zA-Z._\-]+)\)/) {
	print "Start of match: $-[0]\n";
	print "End of match: $+[0]\n";
	print "Start of name: $-[1]\n";
	print "End of name: $+[1]\n";
	print "Name: $1\n";
	print "\n";

	$y = substr($y, 0, $-[0]) . $1 . substr($y, $+[0]);
}

print "Final y: $y\n";
