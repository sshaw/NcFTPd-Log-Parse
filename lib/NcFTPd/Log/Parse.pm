package NcFTPd::Log::Parse;

use strict;
use warnings;
use vars qw{$VERSION};

use File::Basename;
use Carp;
use NcFTPd::Log::Parse::Misc;
use NcFTPd::Log::Parse::Session;
use NcFTPd::Log::Parse::Xfer;

$VERSION = '0.001';

my %PARSERS = (
    xfer => 'NcFTPd::Log::Parse::Xfer',
    sess => 'NcFTPd::Log::Parse::Session',
    misc => 'NcFTPd::Log::Parse::Misc'
);

$PARSERS{session} = $PARSERS{sess};

sub new
{
    my $class = shift;
    croak 'usage: NcFTP::Log::Parse->new($file [, %options ] | %options)' unless @_;

    my $file    = shift if @_ % 2;
    my %options = @_;
    my $parser;

    if(defined $file) {
	my $basename      = basename($file);
	my $known_parsers = join '|', keys %PARSERS;
	if($basename =~ /\A($known_parsers)/i) {
	    $parser = $PARSERS{lc $1};
	}
    }
    else {
	for my $format (keys %PARSERS) {
	    if(defined $options{$format}) {
		$file   = $options{$format};
		$parser = $PARSERS{$format};
		last;		    
	    }
	}
    }

    croak 'Cannot determie what parser to use, try setting it explicitly' unless $parser;

    $parser->new($file, %options);
}

1;

__END__

=head1 NAME

NcFTPd::Log::Parse - parse NcFTPd xfer, session, and misc logs

=head1 SYNOPSIS

  use NcFTPd::Log::Parse;
  $parser = NcFTPd::Log::Parse->new(xfer => 'xfer.20100101'); # Parse xfer log
  $parser = NcFTPd::Log::Parse::Xfer->new('ftp.log');         # Same as above

  while($line = $parser->next) {
    if($line->{type} eq 'S') {	# "Store" operation 
      print 'Upload';  
      $line->{pathname};
      $line->{size};
      # ... 
    }
  }

  # Check for an error, otherwise it was EOF
  if($parser->error) {
    die 'Parsing failed: ' . $parser->error;
  }

  $parser = NcFTPd::Log::Parse->new(xfer => 'xfer.20100101', expand => 1);  # Expand certain entries
  $line   = $parser->next;
  $line->{type}   # Expanded 'S' to  'store'
  $line->{notes}  # Expanded 'SfPs' to ['Used sendfile', 'PASV connection']

  # Load parser based on the log's name (using NcFTPd's default log names)
  $parser = NcFTPd::Log::Parse->new('xfer.20100101');  
  $parser = NcFTPd::Log::Parse->new('session.20100101'); 
  
=head1 DESCRIPTION
  
The C<NcFTPd::Log::Parse> package is composed of 3 parsers:

=over 2

=item L<NcFTPd::Log::Parse::Xfer>

=item L<NcFTPd::Log::Parse::Misc>

=item L<NcFTPd::Log::Parse::Session>

=back

A parser can be created via the factory class C<NcFTPd::Log::Parse>:

    $parser = NcFTPd::Log::Parse->new(xfer => 'ftp.log');    

Or it can be created directly:

    $parser = NcFTPd::Log::Parse::Xfer->new('ftp.log');    

C<new> will C<croak> if an error is encountered.

Options can be provided to ether call to C<new> via a hash:

    $parser = NcFTPd::Log::Parse->new(xfer => 'ftp.log', expand => 1);    

Lines are parsed on demand by calling the parser's C<next> method:

    $fields = $parser->next;

Each call to C<next> returns a hash reference. 

On error and EOF C<undef> is returned. In order to dicern between the two you must check the C<error> method:

    if($parser->error) {
       # it wasn't EOF
    } 

=head1 LOG FORMAT



=head1 METHODS

=over 2

=item C<new($file [, %options ] | %options)>

Create a parser for C<$file> or the file specified speficied by the            

=item C<next>

Parse the next line in the log. 

The keys contained in the hash are dependant upon the type of log being parsed. 

=item C<error>
  
Error message 

=back

=head1 AUTHOR

Skye Shaw <sshaw AT lucas.cis.temple.edu>
 
