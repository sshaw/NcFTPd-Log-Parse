package NcFTPd::Log::Parse::Xfer;

use strict;
use warnings;
use base 'NcFTPd::Log::Parse::Base';

# Field names
use constant {
    #linked => ''    
    DURATION   	      => 'duration',
    EMAIL      	      => 'email',
    HOST       	      => 'host',
    MODE	      => 'mode',
    NOTES             => 'notes',
    PATHNAME   	      => 'pathname',
    PATTERN   	      => 'pattern',
    RATE              => 'rate',
    RECURSION         => 'recursion',  
    RESERVED1  	      => 'reserved1',
    RESERVED2  	      => 'reserved2',
    RESERVED3  	      => 'reserved3',
    SESSION_ID	      => 'session_id',
    SIZE              => 'size',
    START_OF_TRANSFER => 'start_of_transfer',
    STARTING_OFFSET   => 'starting_offset',
    STARTING_SIZE     => 'starting_size',
    STATUS	      => 'status',
    SUFFIX            => 'suffix',
    # Transfer type 
    TYPE              => 'type',
    OPERATION	      => 'operation',
    USER              => 'user'
};

my %TRANSFER_NOTES = (
    Df => 'FTP default data connection (non-passive out to port 20) was used (rare)', #change this
    Po => 'PORT connection',
    Ps => 'PASV connection',
    Mm => 'Used memory mapped I/O', 
    Bl => 'Used block transfer mode', 
    Sf => 'Used sendfile'
);

my @TRANSFER_STATUSES = __PACKAGE__->_transfer_statuses;
my %COMMON_REGEX = __PACKAGE__->_common_regex;

$COMMON_REGEX{optdigit} = '-1|\d+';
$COMMON_REGEX{notes} = join '|', keys %TRANSFER_NOTES;

# Log entry definitions
my $CHMOD = {
    name   => 'chmod',
    fields => [ PATHNAME, MODE, RESERVED1, RESERVED2, USER, EMAIL, HOST, SESSION_ID ],
    regex  => qr{
	(.+),      
	(\d{3}),   # Permissions 
	(.*?),     # Reserved
	(.*?),     # Reserved
	(.+),      # User        
	(.*?),     # "Email" (anonymous login password)
        (.+),      # "Host"
	($COMMON_REGEX{session}),
    }x
};

my $DELETE = {			
    name   => 'delete',
    fields => [ PATHNAME, RESERVED1, RESERVED2, RESERVED3, USER, EMAIL, HOST, SESSION_ID ],
    regex  => qr{
	(.+),     # Path of target
	(.*?),    # Reserved
	(.*?),    # Reserved
	(.*?),    # Reserved
	(.+),     # User
	(.*?),    # "Email" (anonymous login password)
	(.+),     # Host 
	($COMMON_REGEX{session}), # Session   
    }x
};

my $LINK = {
    name   => 'link',
    # need to fix pathname names
    fields => [ PATHNAME, RESERVED1, PATHNAME, RESERVED2, USER, EMAIL, HOST, SESSION_ID ],
    regex  => qr{
	(.+),     # Path of existing file
	(to),     # Reserved, hardcoded to "to"
	(.+),     # Path of linked file
	(.*?),    # Reserved
	(.+),     # User
	(.*?),    # "Email" (anonymous login password)
	(.+),     # Host 
	($COMMON_REGEX{session}), 
    }x
};

my $LIST = {			
    name   => 'listing',
    fields => [ PATHNAME, STATUS, PATTERN, RECURSION, USER, EMAIL, HOST, SESSION_ID ],
    regex  => qr{
	(.+), 		   	  # Path 
	($COMMON_REGEX{status}),  # Transfer status
	(.*?), 		   	  # Filter pattern
	((?:RECURSIVE)?),  	  # Recursive directory transversial
	(.+), 		   	  # User
	(.*?), 		   	  # "Email" (anonymous login password)
	(.+), 		   	  # Host 
	($COMMON_REGEX{session}), 
    }x
};

my $STORE = {
    name   => 'store',
    fields => [ PATHNAME, SIZE, DURATION, RATE, USER, EMAIL, HOST, SUFFIX, STATUS, 
		TYPE, NOTES, START_OF_TRANSFER, SESSION_ID, STARTING_SIZE, STARTING_OFFSET ],
    regex => qr{
	(.+),      	    	   # Path
	(\d+),   	    	   # Size
	($COMMON_REGEX{decimal}),  # Durtaion
	($COMMON_REGEX{decimal}),  # Transfer rate
	(.+),      	    	   # User
	(.*?),      	    	   # Email
	(.+),     	    	   # Peer         
	((?:\.\w+)?),	    	   # Content "translation" (file extention)
	($COMMON_REGEX{status}),   # Transfer status
	(A|I),		    	   # FTP transfer mode
	($COMMON_REGEX{notes}),    # Notes about the transfer
	(\d+),		    	   # Start of transfer
	($COMMON_REGEX{session}),  
	($COMMON_REGEX{optdigit}), # File size at start of the transfer
	($COMMON_REGEX{optdigit})  # Position of file start of the transfer
    }x
};

my $MKDIR = {
    name   => 'mkdir',
    fields => $DELETE->{fields},
    regex  => $DELETE->{regex}
};

my $RENAME = {
    name   => 'rename',
    fields => $LINK->{fields},
    regex  => $LINK->{regex}
};

my $RETRIEVE = {
    name   => 'retrieve',		
    fields => $STORE->{fields},
    regex  => $STORE->{regex}
};

my %LOG_ENTRIES = (
    C => $CHMOD,
    D => $DELETE,
    L => $LINK,
    M => $MKDIR,
    N => $RENAME,
    R => $RETRIEVE,
    S => $STORE,  
    T => $LIST
);

sub _expand_field
{
    my ($self, $name, $value) = @_;

    if($name eq TYPE) {
	$value = $LOG_ENTRIES{$value}->{name};
    }
    elsif($name eq NOTES) {
	my @notes = grep length, split /($COMMON_REGEX{notes})/, $value;	
	$value = [ map $TRANSFER_NOTES{$_}, @notes ];
    }

    $value;
}

sub _parse_entry
{
    my ($self, $fields) = @_;     

    return unless $fields and $fields =~ /^(\w),(.+)/;

    my $op = $1;
    my $details = $2;
    my $entry;

    #TODO: Provide line number on error
    if(!defined $LOG_ENTRIES{$op}) {
	$self->{error} = "Unknown operation '$op'";
    }
    else {
	my @keys = @{$LOG_ENTRIES{$op}->{fields}};
	my @values = $details =~ $LOG_ENTRIES{$op}->{regex};

	#print "R: $LOG_ENTRIES{$op}->{regex}\n $details\n";
	
	if(@values) {
	  $entry->{&OPERATION} = $op;
	  @$entry{@keys} = @values;       
	}
	else {
	  $self->{error} = "Unrecognized format for line: $fields";
	}
    }		      
   
    $entry;
}

1;
