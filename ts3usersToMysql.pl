#!/usr/local/bin/perl

# Teamspeak 3 Users Top10 per time on server
# this script has to be executed every 5 minutes and polls the users currently on the server
# if you want another timespan than 5 minutes, please modify the mysql statement at the end
#
# create a query login name+password in your TS3 server an put it into line 31 and also 
# a appropriate database as following: (my testdatabase here is called munin and the new table is named ts3top)
# CREATE TABLE IF NOT EXISTS `munin`.`ts3top` (`CLDBID` INT NOT NULL ,  `CLNAME` VARCHAR(64) NOT NULL ,  `Minutes` BIGINT,  PRIMARY KEY (`CLDBID`)) ENGINE = InnoDB DEFAULT CHARACTER SET = utf8;
# dont forget to grant your mysql user privileges for this database

use strict;
use Net::Telnet;
use DBI;

my ($db_user, $db_name, $db_pass) = ('myts3mysqluser', 'myts3mysqldb', 'mySecretMysqlPassword');


#################
## telnet part ##
#################

# establish some global variables
my $HOSTNAME = "127.0.0.1";
my $HOSTPORT = "10011";
my $logfile  = "ts3perl.log";

my $telnet = new Net::Telnet ( Timeout=>10, Errmode=>'die', Input_log => $logfile);
$telnet->open(Host => $HOSTNAME, Port => $HOSTPORT);
$telnet->waitfor('/Welcome */i');
$telnet->print('login ts3queryUsername ts3queryPassword');
$telnet->waitfor('/error id=0 msg=ok/i');
$telnet->print('use sid=1');
$telnet->waitfor('/error id=0 msg=ok/i');
$telnet->print("clientlist");
my @TELNETRAW = $telnet->waitfor('/error id=0 msg=ok/i');
$telnet->close;

##############################
## string modification part ##
##############################

my @clients = split( '\|' , @TELNETRAW[0]);

my $CLDBID      = "";
my $CLNAME      = "";

#### open connection to database
my $dbh = DBI->connect("DBI:mysql:database=$db_name", $db_user, $db_pass);

foreach my $client ( @clients )
{
        # process client only if clienttype 0 - normal teamspeak client
        if ($client =~ m/client_type=0/)
        {
#               print "$client \n\n";

                my @clientline = split(' ', $client);


                ##              
                foreach my $clientpart ( @clientline )
                {
                        ## process client_datbase_id
                        if ($clientpart =~ m/^client_database_id=/)
                        {
                                # remove "client_database_id=" from client_database_id=42 
                                my @TMPCLDBID = split("=", $clientpart);
                                $CLDBID = @TMPCLDBID[1]
                        }

                        ## process client_nickname
                        if ($clientpart =~ m/^client_nickname=/)
                        {
                                # remove trailing client_nickname= from string
                                my @TMPCLNAME = split("=", $clientpart);
                                $CLNAME = @TMPCLNAME[1];
                                ## clean up TS names from st**id id**ts who use every special char UTF16 has available in their TS names ....
                                $CLNAME =~ s/[^a-zA-Z0-9_-]/_/g;
                        }

                }

                ## INSERT INTO DATABASE

                my $sth = $dbh->prepare('INSERT INTO ts3top (CLDBID, CLNAME, Minutes) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE CLNAME=? ,Minutes=Minutes+5 ');

                $sth->execute($CLDBID, $CLNAME, 5, $CLNAME) or die $DBI::errstr;;

                $sth->finish();

        }
}
        
## disconnect from database
$dbh->disconnect();

                


               
