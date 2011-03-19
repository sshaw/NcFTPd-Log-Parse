package NcFTPd::Log::Parse::Misc;

use strict;
use warnings;
use base 'NcFTPd::Log::Parse::Base';

# Currently misc logs entries do not need further parsing
sub _parse_entry { { message => $_[1] } }

1;
