#!/usr/bin/perl
#
# this is the updated version from top10 ts user script
# output looks like: https://raw.githubusercontent.com/mkirbst/teamspeak/master/pic-ts3top10detailed.png

use strict;
use Net::Telnet;
use DBI;

my $LOGFILE  = "ts3userdetails.log";           # watch this file for additional debug output if the script can't poll information from the$

# TS3 server variables
my $TS3_HOSTNAME = "127.0.0.1";
my $TS3_HOSTPORT = "10011";
my $TS3_QUERYLOGIN = "TS3QUERADMINUSER";
my $TS3_QUERYPASSWORD = "TS3QUERYADMINPW";     # replace this example with your valid TS3 queryadmin server password

# mysql variables
my $DB_DATABASE = "ts3db";
my $DB_USERNAME = "MYSQLUSER";
my $DB_PASSWORD = "MYSQLPW";


#################
## telnet part ##
#################
my $TSCOUNTER = 0;
my $TELNETRAWSTRING = "";
my $telnet = new Net::Telnet ( Timeout=>10, Errmode=>'return', Input_log => $LOGFILE);
$telnet->open(Host => $TS3_HOSTNAME, Port => $TS3_HOSTPORT);
$telnet->waitfor('/Welcome */i');
$telnet->print("login $TS3_QUERYLOGIN $TS3_QUERYPASSWORD");
$telnet->waitfor('/error id=0 msg=ok/i');
$telnet->print('use sid=1');
$telnet->waitfor('/error id=0 msg=ok/i');
## poll client details as long as we get error 1281 - empty result
# mystic: teamspeak delivers 32 results, beginning at the start parameter given by start=n
# BUT: to get ALL results, you have to choose step width 16, not 32 as every normal human would be expect...
my $TMPTELNET = "";
do
{
        $telnet->print("clientdblist start=".$TSCOUNTER*16);
        my @TELNETRAW = $telnet->waitfor('/error id=/i');
        $TMPTELNET = @TELNETRAW[0];
        $TSCOUNTER++;
        $TELNETRAWSTRING .= $TMPTELNET;
}
while(!($TMPTELNET =~ /^1281/));
$telnet->close;

##############################
## string modification part ##
##############################

## my @clients = split( '\|' , @TELNETRAW[0]);
my @clients = split( '\|' , $TELNETRAWSTRING);
my $CLDBID      = "";
my $CLNAME      = "";
my $CLCREATED   = "";
my $CLLASTCON   = "";
my $CLTOTCON    = "";
my $CLLASTIP    = "";

#### open connection to database
my ($db_user, $db_name, $db_pass) = ($DB_USERNAME, $DB_DATABASE, $DB_PASSWORD);
my $dbh = DBI->connect("DBI:mysql:database=$db_name", $db_user, $db_pass);

foreach my $client ( @clients )
{
        my @clientline = split(' ', $client);
        foreach my $clientpart ( @clientline )
        {
                if ($clientpart =~ m/^cldbid=/)
                {
                        # remove "client_database_id=" from client_database_id=42 
                        my @TMPCLDBID = split("=", $clientpart);
                        $CLDBID = @TMPCLDBID[1];
#                       print( $CLDBID."\n");
                }
            
                ## process client_nickname
                if ($clientpart =~ m/^client_nickname=/)
                {
                        # remove trailing client_nickname= from string
                        my @TMPCLNAME = split("=", $clientpart);
                        $CLNAME = @TMPCLNAME[1];

                        ## TS3 server replaces whitespaces in player or channel names with \s, we replace \s by underscore
                        $CLNAME =~ s/\\s/_/g;

                        ## clean up teamspeak client names
                        $CLNAME =~ s/[^a-zA-Z0-9_-]/_/g;
                }

                if ($clientpart =~ m/^client_created=/)
                {
                        my @TMPCLCREATED = split("=", $clientpart);
                        $CLCREATED = @TMPCLCREATED[1];
                }
            
                if ($clientpart =~ m/^client_lastconnected=/)
                {
                        my @TMPCLLASTCON = split("=", $clientpart);
                        $CLLASTCON = @TMPCLLASTCON[1];
                }
            

                if ($clientpart =~ m/^client_totalconnections=/)
                {
                        my @TMPCLTOTCON = split("=", $clientpart);
                        $CLTOTCON = @TMPCLTOTCON[1];
                }
            
                if ($clientpart =~ m/^client_lastip=/)
                {
                        my @TMPCLLASTIP = split("=", $clientpart);
                        $CLLASTIP = @TMPCLLASTIP[1];
                }

        }


        my $sth = $dbh->prepare('UPDATE ts3top SET CLCREATED=?, CLLASTCON=?, CLCONCOUNT=?, CLLASTIP=? WHERE CLDBID=? ');
        $sth->execute($CLCREATED, $CLLASTCON, $CLTOTCON, $CLLASTIP, $CLDBID) or die $DBI::errstr;;
##      print("DEBUG: ".$CLDBID." ".$CLCREATED." ".$CLLASTCON." ".$CLTOTCON." ".$CLLASTIP." ".$CLDBID."\n");
        $sth->finish();
}

## disconnect from database
$dbh->disconnect();
