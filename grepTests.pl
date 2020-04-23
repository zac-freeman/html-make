my @array = ("test one", "test two", "test tube", "bazinga");
if (grep(/^bazinga$/, @array)) {
	print("bazinga spotted\n");
}

my @emptyArray = ();
if (grep(/^bazinga$/, @emptyArray)) {
	print("empty array??\n");
}

my @undefArray = undef;
if (grep(/^bazinga$/, @undefArray)) {
	print("undef array??\n");
}

my @arrayOfUndef = (undef);
if (grep(/^bazinga$/, @arrayOfUndef)) {
	print("array of undef???\n");
}

my @undefinedArray;
if (grep(/^bazinga$/, @undefinedArray)) {
	print("undefined array????\n");
}


if (grep(/^bazinga$/, @actuallyUndefinedArray)) {
	print("actually undefined array?????\n");
}
