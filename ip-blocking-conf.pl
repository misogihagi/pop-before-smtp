# This config file can be used to run an alternate IP-monitoring daemon than
# the normal pop-before-smtp functionality:  it looks for attacking IPs and
# uses iptables (or ipchains) to temporarily prevent any access from an IP
# address that we think is trying to break in or probe for user names.  (This
# is based on an earlier implementation by Anton V. Popivnenko.)
#
# To use this, run "pop-before-smtp --config=/path/ip-blocking-conf.pl" either
# manually, or create an init file for it (similar to the one used for starting
# up a normal pop-before-smtp script).
#
# You can configure the patterns to look for login failures from SSHD, POP3,
# and/or FTP, as you see fit.

use strict;
use vars qw(
    $pat $out_pat $write $flock $debug $reprocess $grace $logto %file_tail
    @mynets %db $dbfile $dbvalue
    $mynet_func $tie_func $flock_func $add_func $del_func $sync_func
    $tail_init_func $tail_getline_func $log_func
    $PID_pat $IP_pat $OK_pat $FAIL_pat $OUT_pat $cmdformat
);

#
# Override the default options here (or use the command-line options):
#

# The 1st %s gets "-A" or "-D"; the 2nd %s gets the attacker's IP address.
$cmdformat = 'iptables %s INPUT -s %s -j REJECT';
#$cmdformat = 'ipchains %s input -s %s -j REJECT';

# Set $debug to output some extra log messages (if logging is enabled).
#$debug = 1;
#$logto = '-'; # Log to stdout.
#$logto = '/var/log/ip-blocking';

# Override the DB hash file we will create/update (".db" gets appended).
# (We update an actual DB file so that we can easily list the IPs we've
# added, and ensure that the list survives if the daemon is restarted).
$dbfile = '/var/lib/ip-blocking';
$flock = 0; # We use this file exclusively.

# A 3-hour IP-blocking period before the IP address is expired.
$grace = 3*60*60;

# Set the log file we will watch for attacks.
#$file_tail{'name'} = '/var/log/secure';
#$file_tail{'name'} = '/var/log/messages';
$file_tail{'name'} = '/var/log/syslog';

# This is for catching login errors on SSHD only.
$pat = '^(... .. ..:..:..).+Failed password.+from\s+(\d+\.\d+\.\d+\.\d+)';

# This is for catching POP3, FTP, and SSHD errors.  Customize as needed.
#$pat = '^(... .. ..:..:..).+(?:authentication failure|Login failure).+'
#     . '(?:rhost=|host=\[)(\d+\.\d+\.\d+\.\d+)';

# We must configure our override functions.
$mynet_func = \&mynet_ipblock;
$add_func = \&add_ipblock;
$del_func = \&del_ipblock;

sub mynet_ipblock
{
    # You'll probably want to edit this (it specifies IP ranges to ignore).
    '127.0.0.0/8 192.168.1.1/24';
}

sub add_ipblock
{
    my($ip) = @_;
    $db{$ip} = $dbvalue;
    system(sprintf($cmdformat, '-A', $ip));
}

sub del_ipblock
{
    my($ip) = @_;
    system(sprintf($cmdformat, '-D', $ip));
    delete $db{$ip};
}

1; ## THIS LINE MUST REMAIN LAST IN THE FILE! ##
