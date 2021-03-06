# This config file is a perl library that can override various aspects of the
# pop-before-smtp script's setup.  Install it as /etc/pop-before-smtp-conf.pl

# There's quite a bit of sample stuff after the options, so you probably don't
# need to read through all of this.  If you're using Postfix and UW POP/IMAP,
# you can likely just use the default setup without any changes.  The most
# common changes needed are to pick the right $pat variable for your POP/IMAP
# software, ensure that the mail-log name is right, and perhaps uncomment a
# section with the support for a different SMTP (other than Postfix).  See the
# contrib/README.QUICKSTART file for step-by-step instructions on how to
# install and test your setup.

use strict;
use vars qw(
    $pat $out_pat $write $flock $debug $reprocess $grace $logto %file_tail
    @mynets %db $dbfile $dbvalue $logtime_pat
    $mynet_func $tie_func $flock_func $add_func $del_func $sync_func
    $tail_init_func $tail_getline_func $log_func
    $PID_pat $IP_pat $OK_pat $FAIL_pat $OUT_pat
);

#
# Override the default options here (or use the command-line options):
#

# Clear to avoid our exclusive file locking when updating the DB.
#$flock = 0;

# Set $debug to output some extra log messages (if logging is enabled).
#$debug = 1;
#$logto = '-'; # Log to stdout.
#$logto = '/var/log/pop-before-smtp';

# Override the DB hash file we will create/update (".db" gets appended).
#$dbfile = '/etc/postfix/pop-before-smtp';

# Override the value that gets put into the DB hash.
#$dbvalue = 'ok';

# A 30-minute grace period before the IP address is expired.
#$grace = 30*60;

# Set the log file we will watch for pop3d/imapd records.
#$file_tail{'name'} = '/var/log/maillog';
#$file_tail{'name'} = '/Library/Logs/MailService/AppleMailServer.IMAP.log';

# ... or we'll try to figure it out for you.
if (!-f $file_tail{'name'}) {
    foreach (qw( /var/log/mail/info /var/log/mail.log
		 /var/log/messages /var/adm/messages )) {
	if (-f $_) {
	    $file_tail{'name'} = $_;
	    last;
	}
    }
}

# If you need to define a custom PATH (for instance, if you're using Postfix
# and postconf is someplace wierd), uncomment and customize this.
#$ENV{'PATH'} = '/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/sbin:/usr/local/bin';

# These parameters control how closely the watcher tries to follow the
# logfile, which affects how much resources it consumes, and how quickly
# people can smtp after they have popped.  These values are documented in
# the File::Tail pod (run "perldoc File::Tail" to find out details).
# These commented-out values are the ones Daniel Roesen prefers.

#$file_tail{'maxinterval'} = 2;
#$file_tail{'interval'} = 1;
#$file_tail{'adjustafter'} = 3;
#$file_tail{'resetafter'} = 30;
#$file_tail{'tail'} = -1;

=cut #============================ syslog =============================START=
# If you want to output a log file of what pop-before-smtp is doing, you have
# a few choices: either set $logto above, comment-out the two surrounding
# =cut lines to use this syslog section, or put a reference to your own
# custom logging function into $log_func.

use Sys::Syslog qw(:DEFAULT setlogsock);
# Try uncommenting this if you get no syslog output:
#setlogsock('unix');  # Valid arg values: inet, unix, stream, console.
openlog('pop-before-smtp', 'pid', 'mail');
$log_func = \&syslog;
=cut #============================ syslog ===============================END=

=cut #-------------------------- File::Tail ---------------------------START-
# If you want to use the File::Tail module to read the logfile, comment-out
# the two surrounding =cut lines.  (By default pop-before-smtp now uses its
# own, simpler file-tailing functions.)

use File::Tail;

$tail_init_func = \&init_FileTail;
$tail_getline_func = \&getline_FileTail;

sub init_FileTail
{
    $::ft_handle = File::Tail->new(%file_tail);
}

sub getline_FileTail
{
    $::ft_handle->read;
}

=cut #-------------------------- File::Tail -----------------------------END-

=cut #----------------------- Read log on stdin -----------------------START-
# If you want to have syslog run pop-before-smtp and send it log lines via
# stdin, comment-out the two surrounding =cut lines and setup your syslog
# to have an entry like this:
#
#    mail.info                     | exec /usr/local/sbin/pop-before-smtp
#
# Also, make sure there's not a pop-before-smtp init script installed.

$file_tail{'name'} = '-';   # Just for the sake of --dumpconfig

$tail_init_func = sub { };
$tail_getline_func = \&getline_stdin;

sub getline_stdin
{
    my $line = <STDIN>;
    if (!defined $line) {
        die "EOF on stdin -- exiting\n";
    }
    $line;
}
=cut #----------------------- Read log on stdin -------------------------END-

############################# START OF PATTERNS #############################
#
# Pick one of these values for the $pat variable OR define a subroutine
# named "custom_match" to handle a more complex match scenario (there's
# an example below).  Feel free to delete all the stuff you don't need.
#
# To enable an entry, just delete the "#" at the start of all the lines
# *after* the initial comment line(s).  If the entry of your choice also
# provides $out_pat, you should uncomment that variable as well, which
# allows us to keep track of users who are still connected to the server
# (e.g. Thunderbird caches open IMAP connections).
#
# Note also that the servers that require multiple log lines be read to
# get all the needed info have a setup with 3 $NAME_pat variables instead
# of a single "$pat" variable.  Uncomment all 3 and we'll define a multi-
# line-matching custom_match() subroutine for you.
#
# Technical:  if you want to define a new $pat regex, make sure that you
# include the string "[LOGTIME]" near the start because this string will
# be replaced by the final value of the $logtime_pat variable, and this
# handles the matching and returning of the first value the code needs:
# the line's timestamp.  There must also be a 2nd value returned from the
# regular expression:  the IP number.
#
############################# START OF PATTERNS #############################

# If your logfile has a non-standard time-stamp, you may need to define the
# $logtime_pat value here, or use one of the known variations included next
# to the relevant patterns.  The value should include parentheses, and (for
# maximum flexibility) should be able to match the time on any log line.
# This defaults to "(\w\w\w +\d+ \d+:\d+:\d+)" if left undefined.

#$logtime_pat = '(\d\d\d\d-\d\d-\d\d \d+:\d+:\d+)';

# For UW POP/IMAP. This is the DEFAULT $pat (without an $out_pat, by default).
#$pat = '^[LOGTIME] \S+ (?:ipop3s?d|imaps?d)\[\d+\]: ' .
#    '(?:Login|Authenticated|Auth|APOP) user=\S+ ' .
#    'host=(?:\S+ )?\[(\d+\.\d+\.\d+\.\d+)\]';
#$out_pat = '^[LOGTIME] \S+ (?:ipop3s?d|imaps?d)\[\d+\]: ' .
#    '(?:Logout|Autologout|Killed.*?|Command stream end of file.*?) user=\S+ host=(?:\S+ )?\[(\d+\.\d+\.\d+\.\d+)\]';

# Some folks need a little different match for UW ipop3d/imapd:
#$pat = '^[LOGTIME] \S+ (?:ipop3s?d|imaps?d)\[\d+\]: \[[^]]+\]' .
#    '(?:Login|Authenticated|Auth|APOP) user=\S+ ' .
#    'host=(?:\S+ )?\[(\d+\.\d+\.\d+\.\d+)\]';

# For GNU pop3d
#$pat = '^[LOGTIME] \S+ gnu-pop3d\[\d+\]: ' .
#    'User .+ logged in with mailbox .+ from (\d+\.\d+\.\d+\.\d+)';

# A fairly modern Qpopper pattern, when using syslog.
#$pat = '^[LOGTIME] \S+ (?:in\.q|q)?popper[^[]*\[\d+\]: \([^)]*\) ' .
#    'POP login by user "[^"]+" at \([^)]+\) (\d+\.\d+\.\d+\.\d+)';

# The same Qpopper pattern as above, but matches Qpopper's own logging.
#$pat = '^[LOGTIME] \[popper\] \([^)]*\) ' .
#    'POP login by user (?:"[^"]+"|\S+) at \([^)]+\) (\d+\.\d+\.\d+\.\d+)';

# For Qpopper POP/APOP Server (matches in.qpopper, qpopper, and popper).
#$pat = '^[LOGTIME] \S+ (?:in\.q|q)?popper\[\d+\]: Stats: \S+ ' .
#    '\d+ \d+ \d+ \d+ (?:\S+ )?(\d+\.\d+\.\d+\.\d+)';

# Chris D.Halverson's pattern for Qpopper 3.0b29 on Solaris 2.6
#$logtime_pat = '(... ... .. \d+:\d+:\d+ \d{4})';
#$pat = '^[LOGTIME] \[\d+\] Stats:\s+\w+ ' .
#    '\d \d \d \d [\w\.]+ (\d+\.\d+\.\d+\.\d+)';

# For Cyrus (including a tweak for IP addrs that don't resolve):
#$pat = '^[LOGTIME] \S+ (?:cyrus/)?(?:pop3|imap)[ds]?\[\d+\]: ' .
#    'login: .*?\[[:f]*(\d+\.\d+\.\d+\.\d+)\] .* User logged in';

# For Courier-POP3 and Courier-IMAP:
#$pat = '^[LOGTIME] (?:\[|\S+ )(?:pop3|imap|couriertcp)(?:d|d-ssl|login)\]?: ' .
#    'LOGIN, user=\S+, ip=\[[:f]*(\d+\.\d+\.\d+\.\d+)\]';
#$out_pat = '^[LOGTIME] (?:\[|\S+ )(?:pop3|imap|couriertcp)(?:d|d-ssl|login)\]?: ' .
#    '(?:LOGOUT|TIMEOUT|DISCONNECTED), user=\S+, ip=\[[:f]*(\d+\.\d+\.\d+\.\d+)\]';

# For qmail's pop3d:
#$pat = '^[LOGTIME] \S+ vpopmail\[\d+\]: vchkpw: ' .
#    'login \[\S+\] from (\d+\.\d+\.\d+\.\d+)';

# For cucipop, matching a sample from Daniel Roesen:
#$pat = '^[LOGTIME] \S+ cucipop\[\d+\]: \S+ ' .
#    '(\d+\.\d+\.\d+\.\d+) \d+, \d+ \(\d+\), \d+ \(\d+\)';

# A Modern vm-pop3d can use a normal, 1-line pattern:
#$pat = '^[LOGTIME] \S+ vm-pop3d\[\d+\]: ' .
#    'User .+? logged in from (\d+\.\d+\.\d+\.\d+)';

# Older vm-pop3d -- needs to match 2 log entries (uncomment all 3 *_pat lines).
#$PID_pat = '^[LOGTIME] \S+ vm-pop3d\[(\d+)\]: ';
#$IP_pat = $PID_pat . 'Connect from (\d+\.\d+\.\d+\.\d+)';
#$OK_pat = $PID_pat . 'User .+? logged in';

# For popa3d -- needs to match 2 log entries (uncomment all 3 *_pat lines).
#$PID_pat = '^[LOGTIME] \S+ popa3d\[(\d+)\]: ';
#$IP_pat = $PID_pat . 'Session from (\d+\.\d+\.\d+\.\d+)';
#$OK_pat = $PID_pat . 'Authentication passed for ';

# For *patched* popa3d (see the patch in the contrib/popa3d dir).
#$pat = '^[LOGTIME] \S+ popa3d\[\d+\]: ' .
#    'Authentication passed for \S+ -- \[(\d+\.\d+\.\d+\.\d+)\]';

# A Perdition pattern.
#$pat = '^[LOGTIME] \S+ perdition\[\d+\]: ' .
#    'Auth: (\d+\.\d+\.\d+\.\d+)\-\>\d+\.\d+\.\d+\.\d+ ' .
#    'user=\"\S+\" server=\"\S+\" port=\"\S+\" status=\"ok\"';

# For solidpop3d (aka spop3d) ** if configured with --enable-logextend! **
#$pat = '^[LOGTIME] \S+ spop3d\[\d+\]: ' .
#    'user \S+ authenticated - (\d+\.\d+\.\d+\.\d+)';

# For spop3d w/o --enabled-logextend (uncomment all 3 *_pat lines).
#$PID_pat = '^[LOGTIME] \S+ spop3d\[(\d+)\]: ';
#$IP_pat = $PID_pat . 'connect from (\d+\.\d+\.\d+\.\d+)';
#$OK_pat = $PID_pat . 'user \S+ authenticated';

# Pattern for teapop (http://www.toontown.org/teapop/) by Patrick Prasse.
#$pat = '^[LOGTIME] \S+ teapop\[\d+\]: ' .
#    'Successful login for .+? \[(\d+\.\d+\.\d+\.\d+)\]';

# For Dovecot POP3/IMAP when using syslog.
#$pat = '^[LOGTIME] \S+ (?:dovecot: )?(?:imap|pop3)-login: ' .
#    'Login: .*? (?:\[|rip=)[:f]*(\d+\.\d+\.\d+\.\d+)[],]';
#$out_pat = '^[LOGTIME] \S+ (?:dovecot: )?(?:imap|pop3)-login: ' .
#    'Disconnected.*? (?:\[|rip=)[:f]*(\d+\.\d+\.\d+\.\d+)[],]';

# For Dovecot POP3/IMAP when it does its own logging.
##$logtime_pat = '(\d\d\d\d-\d+-\d+ \d+:\d+:\d+)';
#$pat = '^dovecot: [LOGTIME] Info: (?:imap|pop3)-login: ' .
#    'Login: .+? rip=[:f]*(\d+\.\d+\.\d+\.\d+),';
#$out_pat = '^dovecot: [LOGTIME] Info: (?:imap|pop3)-login: ' .
#    'Disconnected.*? rip=[:f]*(\d+\.\d+\.\d+\.\d+),';

# For older Dovecot POP3/IMAP when it does its own logging.
#$pat = '^(?:imap|pop3)-login: [LOGTIME] Info: ' .
#    'Login: \S+ \[[:f]*(\d+\.\d+\.\d+\.\d+)\]';
#$out_pat = '^(?:imap|pop3)-login: [LOGTIME] Info: ' .
#    'Disconnected.*? \[[:f]*(\d+\.\d+\.\d+\.\d+)\]';

# For Apple IMAP MAIL Server
#$logtime_pat = '(\w\w\w +\d+ \d\d\d\d \d+:\d+:\d+)';
#$pat = '^[LOGTIME].* IMAP User "[^"]+" ' .
#    'log on successful from (\d+\.\d+\.\d+\.\d+)';

############################## END OF PATTERNS ##############################


=cut #====================== Match Many Patterns ======================START=
# Comment-out (or remove) the two surrounding =cut lines to use this function.

# This is an example of using the custom_match() function to match
# several patterns (allowing you to match multiple pop/imap servers
# at the same time).  Note that you can define logout patterns for
# some, all, or none of the login patterns, as needed.

my(@login, @logout);

$login[0] = $pat;
#$logout[0] = $out_pat;

$login[1] = '... define an extra login pattern here ...';
#$logout[1] = '... define an extra logout pattern, if needed ...';

# ... plus any other patterns you want to define ...

foreach (@login, @logout) {
    next unless defined $_;
    s/\[LOGTIME\]/$logtime_pat/g;
    $_ = qr/$_/;	# Pre-compile the regular expressions.
}

# The mail-log line to match is in $_.
sub custom_match
{
    my($timestamp, $ipaddr);
    foreach my $regex (@logout) {
	if (defined($regex) && (($timestamp, $ipaddr) = /$regex/)) {
	    return ($timestamp, $ipaddr, -1);
	}
    }
    my $j = 0;
    foreach my $regex (@login) {
	if (($timestamp, $ipaddr) = /$regex/) {
	    my $increment = defined($logout[$j]) ? 1 : 0;
	    return ($timestamp, $ipaddr, $increment);
	}
	$j++;
    }
    ( );
}
=cut #====================== Match Many Patterns ========================END=

######################### Alternate DB/SMTP support #########################
#
# If you need to use something other than DB_File, define your own tie,
# sync, and (optionally) flock functions.
#
######################### Alternate DB/SMTP support #########################

=cut #----------------------- Postfix NDBM_File -----------------------START-
# If you comment-out (or remove) the two surrounding =cut lines, we'll use
# NDBM_File instead of DB_File.

use Fcntl;
use NDBM_File;

#$mynet_func = \&mynet_postfix; # Use the default
$tie_func = \&tie_NDBM;
$sync_func = sub { };
$flock = 0;

# We must tie the global %db using the global $dbfile.
sub tie_NDBM
{
    tie %db, 'NDBM_File', $dbfile, O_RDWR|O_CREAT, 0664
	or die "$0: cannot dbopen $dbfile: $!\n";
}
=cut #----------------------- Postfix NDBM_File -------------------------END-

=cut #====================== Postfix BerkeleyDB =======================START=
# If you comment-out (or remove) the two surrounding =cut lines, we'll use
# BerkeleyDB instead of DB_File.

use BerkeleyDB;

#$mynet_func = \&mynet_postfix; # Use the default
$tie_func = \&tie_BerkeleyDB;
$sync_func = \&sync_BerkeleyDB;
$flock = 0;

my $dbh;

# We must tie the global %db using the global $dbfile.  Also sets $dbh for
# our sync function.
sub tie_BerkeleyDB
{
    $dbh = tie %db,'BerkeleyDB::Hash',-Filename=>"$dbfile.db",-Flags=>DB_CREATE
	or die "$0: cannot dbopen $dbfile: $!\n";
}

sub sync_BerkeleyDB
{
    $dbh->db_sync and die "$0: sync $dbfile: $!\n";
}
=cut #====================== Postfix BerkeleyDB =========================END=

=cut #------------------------ qmail tcprules -------------------------START-
# If you comment-out (or remove) the two surrounding =cut lines, we'll use
# the tcprules program instead of maintaining a DB_File hash.

my $TCPRULES = '/usr/local/bin/tcprules';

$mynet_func = \&mynet_tcprules;
$tie_func = \&tie_tcprules;
$sync_func = \&sync_tcprules;
$flock = 0;

sub mynet_tcprules
{
    # You'll probably want to edit this (it specifies IP ranges to ignore).
    '127.0.0.0/8 192.168.1.1/24';
}

my @qnets;

# We leave the global %db as an untied hash and setup a @qnets array.
sub tie_tcprules
{
    # convert 10.1.3.0/28 to 10.1.3.0-15 
    #     and 10.1.0.0/16 to 10.1.
    # because tcprules doesn't understand nnn.nnn.nnn.nnn/bb netmask formats
    foreach (@mynets) {
	if (m#(.*)/(\d+)#) { 
	    $_ = $1; 
	    my $netbits = (32 - $2);
	    while (int($netbits / 8)) { # for every 8 bits, chop a quad
		s/\.[^.]*$//; 
		$netbits -= 8; 
	    }
	    s/(\d+)$/$1.sprintf("-%d",$1 + (2**$netbits) - 1)/e if $netbits > 0;
	    /(\..*){3}/ or s/$/./;
	} 
	push @qnets, $_;
    }
}

sub sync_tcprules
{
    open(RULES, "|$TCPRULES $dbfile $dbfile.tmp") or die "forking tcprules: $!";
    map { print RULES "$_:allow,RELAYCLIENT=''\n" } @qnets, keys %db;
    print RULES ":allow\n";
    close RULES or die "closing tcprules pipe: $!";
    $log_func->('debug', "wrote tcp rules to $dbfile") if $debug;
}
=cut #------------------------ qmail tcprules ---------------------------END-

=cut #========================= Courier SMTP ==========================START=
# If you comment-out (or remove) the two surrounding =cut lines, we'll
# interface with Courier SMTP using DB_File.

my $ESMTPD = '/usr/lib/courier/sbin/esmtpd';

use Fcntl qw(:DEFAULT :flock);
use DB_File;

$dbfile = '/etc/courier/smtpaccess'; # DB hash to write
$dbvalue = 'allow,RELAYCLIENT';

$mynet_func = \&mynet_courier;
$tie_func = \&tie_courier;
$sync_func = \&sync_courier;
$flock_func = \&flock_courier;

sub mynet_courier
{
    '';
}

my $dbh;

sub tie_courier
{
    $dbh = tie %db, 'DB_File', "$dbfile.dat", O_CREAT|O_RDWR, 0666, $DB_HASH
	or die "$0: cannot dbopen $dbfile: $!\n";
    if ($flock) {
	my $fd = $dbh->fd;
	open(DB_FH,"+<&=$fd") or die "$0: cannot open $dbfile filehandle: $!\n";
    }
}

sub flock_courier
{
    my($locking) = @_;
    flock(DB_FH, $locking ? LOCK_EX : LOCK_UN)
	or die "$0: flock_courier($locking) failed: $!\n";
}

sub sync_courier
{
    $dbh->sync and die "$0: sync $dbfile: $!\n" if $write;

    # Reload SMTP Daemon (isn't there a better way to do this?)
    system "$ESMTPD stop; $ESMTPD start";
}
=cut #========================= Courier SMTP ============================END=

=cut #------------------------- Sendmail SMTP -------------------------START-
# If you comment-out (or remove) the two surrounding =cut lines, we'll
# interface with Sendmail SMTP using DB_File.  See the quickstart guide for
# the sendmail.cf changes you'll need to make.  If you find that Sendmail
# isn't recognizing the changes to the DB file, set $signal_sendmail to 1.

use Fcntl qw(:DEFAULT :flock :seek);
use DB_File;

$dbfile = '/etc/mail/popauth'; # DB hash to write

$mynet_func = \&mynet_sendmail;
$tie_func = \&tie_sendmail;
$sync_func = \&sync_sendmail;
$flock_func = \&flock_sendmail;
#$flock_func = \&fcntl_sendmail;

my $signal_sendmail = 0;
my($pid_file, $sendmail_pid);

if ($signal_sendmail) {
    $pid_file = '/var/run/sendmail.pid';
    open(PID, $pid_file) || die "Unable to open $pid_file: $!";
    $_ = <PID>;
    ($sendmail_pid) = /(\d+)/;
    close PID;
}

sub mynet_sendmail
{
    # You'll probably want to edit this (it specifies IP ranges to ignore).
    '127.0.0.0/8 192.168.1.1/24';
}

my $dbh;

# We set the global %db to the opened database hash.  We also set $dbh for
# our sync function, and DB_FH for our flock_DB function.
sub tie_sendmail
{
    $dbh = tie %db, 'DB_File', "$dbfile.db", O_CREAT|O_RDWR, 0666, $DB_HASH
	or die "$0: cannot dbopen $dbfile: $!\n";
    if ($flock) {
	my $fd = $dbh->fd;
	open(DB_FH,"+<&=$fd") or die "$0: cannot open $dbfile filehandle: $!\n";
    }
}

sub sync_sendmail
{
    $dbh->sync and die "$0: sync $dbfile: $!\n";

    while ($signal_sendmail) {
	$log_func->('debug', "about to signal $sendmail_pid") if $debug;
	last if kill(1, $sendmail_pid);
	open(PID, $pid_file) || die "Unable to open $pid_file: $!";
	$_ = <PID>;
	my($new_pid) = /(\d+)/;
	close PID;
	if ($new_pid == $sendmail_pid) {
	    die "Unable to signal sendmail to reread the database.\n";
	}
	$log_func->('debug', "discovered new sendmail_pid: $new_pid") if $debug;
	$sendmail_pid = $new_pid;
    }
}

# Only 1 of these 2 locking functions is used (look for $flock_func above).
sub flock_sendmail
{
    my($locking) = @_;
    flock(DB_FH, $locking ? LOCK_EX : LOCK_UN)
	or die "$0: flock_sendmail($locking) failed: $!\n";
}

sub fcntl_sendmail
{
    my($locking) = @_;
    my $lock = pack('s s l l i', $locking ? F_WRLCK : F_UNLCK, SEEK_SET, 0, 0, 0);
    fcntl(DB_FH, F_SETLKW, $lock)
	or die "$0: fcntl_sendmail($locking) failed: $!\n";
}
=cut #------------------------- Sendmail SMTP ---------------------------END-

=cut #========================= CDB_File SMTP =========================START=
# If you comment-out (or remove) the two surrounding =cut lines, we'll use
# CDB_File instead od DB_File.

use CDB_File;

$tie_func = \&tie_CDB;
$sync_func = \&sync_CDB;
$flock = 0;

# We leave the global %db as an untied hash.
sub tie_CDB
{
}

sub sync_CDB
{
    my $cdb = CDB_File->new($dbfile, "$dbfile.tmp") or die;
    foreach (keys %db) {
	$cdb->insert($_, $dbvalue);
    }
    $cdb->finish;
}
=cut #========================= CDB_File SMTP ===========================END=

############################# Support Routines ##############################

# This section takes care of defining a multi-line-match custom_match()
# subroutine, but only if the user configured our 3 required patterns.

if (defined($PID_pat) && defined($IP_pat) && defined($OK_pat)) {
    eval <<'EOT';
# Some pop services don't put the IP on the line that lets us know that a
# user was properly authenticated.  For these programs, we scan the IP off
# an earlier line and the check the validation by comparing the PID values.
# The regex $IP_pat is used to match the IP number and cache it.  The regex
# $OK_pat is used to match a success message that follows from the same PID.
# If $FAIL_pat is not defined, there can be no intermediate log messages
# with the same PID prior to the $OK_pat.  If $FAIL_pat is defined, we'll
# continue trying to match the $OK_pat value on matching PID lines until we
# either match the $FAIL_pat (in which case the IP is ignored) or the $OK_pat
# (in which case the IP is accepted).  Thus, $FAIL_pat can be either a
# failure log line or a this-PID-is-finished log line common to both success
# and failure.  Finally, an optional $OUT_pat may be defined if you want to
# track active connections -- when defined, any PID that matches the $OK_pat
# will be considered connected until we find a match for $OUT_pat.  It is
# fine if lines that match $OUT_pat would also match $FAIL_pat (such as a
# disconnect message) -- this won't confuse the code.
#
# Keep in mind that $IP_pat, $OK_pat, $OUT_pat, and $FAIL_pat will only be
# applied to lines that match the $PID_pat regex.

    my(%popIPs, %popConnected);

    $FAIL_pat = '.' if !defined $FAIL_pat;
    foreach ($PID_pat, $IP_pat, $OK_pat, $FAIL_pat, $OUT_pat) {
	s/\[LOGTIME\]/$logtime_pat/g if defined $_;
    }

    # The mail-log line to match is in $_.
    sub custom_match
    {
	if (/$PID_pat/o) {
	    my($ts, $pid) = ($1, $2);
	    if (/$IP_pat/o) {
		$popIPs{$pid} = $3;
	    } else {
		my $ip = $popIPs{$pid};
		if (defined $ip) {
		    if ($popConnected{$pid}) {
			if (/$OUT_pat/o) {
			    delete $popConnected{$pid};
			    delete $popIPs{$pid};
			    return ($ts, $ip, -1);
			}
		    } else {
			if (/$OK_pat/o) {
			    if (defined $OUT_pat) {
				$popConnected{$pid} = 1;
				return ($ts, $ip, 1);
			    }
			    delete $popIPs{$pid};
			    return ($ts, $ip, 0);
			}
			if (/$FAIL_pat/o) {
			    delete $popIPs{$pid};
			}
		    }
		}
	    }
	}
	( );
    }
EOT
}

1; ## THIS LINE MUST REMAIN LAST IN THE FILE! ##
