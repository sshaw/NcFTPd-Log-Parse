package NcFTPd::Log::Parse::Session;

use strict;
use warnings;
use base 'NcFTPd::Log::Parse::Base';

# From http://www.ncftp.com/ncftpd/doc/sesslog.html#CloseCodes
my %CLOSE_CODE_DESCRIPTIONS = (
    0  => 'Normal disconnect (client issued QUIT primitive).',
    1  => 'End-of-file on control connection; the client closed the connection but did not issue a QUIT primitive.  This should not be considered an error in most cases.',
    2  => 'Miscellaneous error.',
    3  => 'Client exceeded idle timeout limit.',
    4  => 'Client exceeded login timeout.',
    5  => 'Timed-out while sending to client.',
    6  => 'Lost connection (broken pipe).',
    7  => 'Control connection reset by peer.',
    8  => 'Network I/O error (error reported by read or write system call).',
    9  => 'TCP Wrappers denied the user.',
    10 => 'Too many users already logged on.',
    11 => 'Too many users already logged on to domain.',
    12 => 'Too many users already logged on by the same username.',
    13 => 'Too many users already logged on by the same IP address.',
    14 => 'Bad startup directory.',
    15 => 'Passive data socket failed.',
    16 => 'Passive data connection accept failed.',
    17 => 'Passive data connection accept timed-out.',
    18 => 'Passive data connection accept succeeded, but remote port was under 1024.',
    19 => 'Passive data connection accept succeeded, but remote address was different from that of the control connection and proxy connections are disabled.',
    20 => 'Port data connection attempt to client timed-out.',
    21 => 'Port data connection attempt to client failed.',
    22 => 'Port data connection specified a different remote address than that of the control connection and proxy connections are disabled.',
    23 => 'Port data connection specified an internal network address.',
    24 => 'Port data connection specified a remote port number under 1024.',
    25 => 'Control connection\'s port number was under 1024.',
    26 => 'Socket failed.',
    27 => 'ncftpd_authd exchange state failed.',
    28 => 'ncftpd_authd denied the user.',
    29 => 'ncftpd_authd miscellaneous error.',
    30 => 'Too many failed username/password attempts.',
    31 => 'No logins are allowed during system maintenance (/etc/nologin file exists).',
    32 => 'Anonymous logins not allowed here.',
    33 => 'Non-anonymous logins not allowed here.',
    34 => 'Buffer overflow attempted by client.',
    35 => 'Could not restore user privileges.',
    36 => 'Domain is marked as disabled.',
    37 => 'Timed out during data transfer.',
    38 => 'Wrong protocol (such as HTTP or SMTP) used by client.',
    39 => 'Syntax error in passwd database user record.',
    40 => 'Malformed User Permssions String in passwd database user record or from Authd.',
    41 => 'Malformed Umask in passwd database user record or from Authd.'
);

my $CLOSE_CODES = join '|', keys %CLOSE_CODE_DESCRIPTIONS;
my $DIGITS6  = '(\d*?),' x 6;
my $DIGITS16 = '(\d*?),' x 16;    
my %COMMON_REGEX = __PACKAGE__->_common_regex;
my @FIELD_NAMES = qw{
    user
    email
    host
    session_time
    time_between_commands
    bytes_retrieved
    bytes_stored
    number_of_commands
    retrieves
    stores
    chdirs
    nlists
    lists
    types
    port_pasv
    pwd
    size
    mdtm
    site
    logins
    failed_data_connections
    last_transfer_result
    successful_downloads
    failed_downloads
    successful_uploads
    failed_uploads
    successful_listings
    failed_listings
    close_code
    session_id
};

# Only: last_transfer_result (transfer_status/completion in Xfer/Parser) and close_code (see above)
sub _expand_field
{
    my ($self, $name, $value) = @_;
    $name eq 'close_code' ? $CLOSE_CODE_DESCRIPTIONS{$value} : $value;
}

sub _parse_entry
{
    my ($self, $fields) = @_; 
    my $entry;

    if($fields) {
      #username can be blank, why?
      #REFUSED does not end in session ID, but closecode
	my @values = $fields =~ m{				   
	    ((?:REFUSED|DENIED|.*?)),   # Username (does NcFTPd always remove spaces?)
	    (.*?),		       # "Email" (anonymous login password)
	    (.*?),		       # Host 
	    (\d*?),		       # Session time
	    ((?:$COMMON_REGEX{decimal})?),  # Time between commands
	    $DIGITS16		       # 16 comma separated digits
	    ((?:NONE|$COMMON_REGEX{status})?),   # Status of last transfer
	    $DIGITS6		       # 6 comma separated digits
	    ($CLOSE_CODES)	       # Close code i.e. why the conection was closed	   
	    (?:,($COMMON_REGEX{session})?,)?
	}x;

	if(@values) {
	    @$entry{@FIELD_NAMES} = @values;	    
	    # session_time
# 	    if(!defined $entry->{}) {
# 		$entry->{} = 0;
# 	    }			
		
	}	
    }
    
    $entry;
}


