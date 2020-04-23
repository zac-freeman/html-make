my %hashTable = (
	"a" => "apple",
	"b" => "banana",
	"c" => "cherry"
);

if (exists($hashTable{"a"})) {
	print("entry for a exists\n");
}

if (exists($hashTable{"d"})) {
	print("entry for d exists\n");
}

$x = $hashTable{"d"};


if (!defined($x)) {
	print("x is undefined\n");
}

print("value for x: $x\n");

$hashTableReference = \%hashTable;

$y = $hashTableReference->{"e"};

if (!defined($y)) {
	print("y is undefined\n")
}

my $z = \$hashTableReference->{"a"};
$$z = "avocado";
my $omega = $hashTableReference->{"a"};

print("a is now the key for $omega\n");

my $alpha = \$hashTableReference->{"f"};

if (!defined($$alpha)) {
	print("alpha is undefined\n")
}
