#!/usr/bin/perl

# Teamspeak 3 Users Top10 per time on server
# this script has to be executed every 5 minutes and polls the users currently on the server
# if you want another timespan than 5 minutes, please modify the mysql statement at the end
#
# Please check that you have a sufficient perl environment on your server and you have installed 
# the Net::Telnet module. For example in ubuntu you have to type:
# $ sudo apt-get install libnet-telnet-perl
#
# You also need a mysql database, in which are the values for your ts3users are stored. 
# THE PASSWORD IS A EXAMPLE, PLEASE CHOOSE AN OWN, SECURE PASSWORD AND SET IT UP IN BOOTH FILES, THE PERL AND PHP FILE.. 
# SEE: https://www.schneier.com/blog/archives/2014/03/choosing_secure_1.html
# 
# ---- howto create approriate mysql database ----
# create a query login name+password in your TS3 server an put it into line 31 and also 
# a appropriate database as following: (my testdatabase here is called ts3db and the new table is named ts3top)
#
# $ mysql -u root -p
# mysql> CREATE DATABASE IF NOT EXISTS ts3db;
# mysql> GRANT ALL ON *.* TO 'ts3queryuser'@'localhost' IDENTIFIED BY 'Start123!';
# mysql> CREATE TABLE IF NOT EXISTS `ts3db`.`ts3top`\
#     -> (`CLDBID` INT NOT NULL , `CLNAME` VARCHAR(64) NOT NULL , `Minutes` BIGINT, PRIMARY KEY (`CLDBID`))\ 
#     -> ENGINE = InnoDB DEFAULT CHARACTER SET = utf8;
# mysql> FLUSH PRIVILEGES;
# mysql> QUIT;

use strict;
use Net::Telnet;
use DBI;


my $LOGFILE  = "ts3perl.log"; 		# watch this file for additional debug output if the script can't poll information from the TS3 server

# TS3 server variables
my $TS3_HOSTNAME = "127.0.0.1";
my $TS3_HOSTPORT = "10011";
my $TS3_QUERYLOGIN = "queryadmin";
my $TS3_QUERYPASSWORD = "OmzjE41R";	# replace this example with your valid TS3 queryadmin server password

# mysql variables			
my $DB_DATABASE	= "ts3db";
my $DB_USERNAME = "ts3queryuser";
my $DB_PASSWORD = "Start123!";



#################
## telnet part ##
#################

my $telnet = new Net::Telnet ( Timeout=>10, Errmode=>'die', Input_log => $LOGFILE);
$telnet->open(Host => $TS3_HOSTNAME, Port => $TS3_HOSTPORT);
$telnet->waitfor('/Welcome */i');

$telnet->print("login $TS3_QUERYLOGIN $TS3_QUERYPASSWORD");
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
my ($db_user, $db_name, $db_pass) = ($DB_USERNAME, $DB_DATABASE, $DB_PASSWORD);
my $dbh = DBI->connect("DBI:mysql:database=$db_name", $db_user, $db_pass);

foreach my $client ( @clients )
{
        # process client only if clienttype 0 - normal teamspeak client
        if ($client =~ m/client_type=0/)
        {
                my @clientline = split(' ', $client);
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

                                ## TS3 server replaces whitespaces in player or channel names with \s, we replace this by underscore
                                $CLNAME =~ s/\\s/_/g;

                                ## clean up TS names from st**id id**ts who use every special char UTF16 has available in their TS names ....
                                $CLNAME =~ s/[^a-zA-Z0-9_-]/_/g;
                        }

                }
                ## INSERT INTO DATABASE
                my $sth = $dbh->prepare('INSERT INTO ts3top (CLDBID, CLNAME, Minutes) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE CLNAME=? ,Minutes=Minutes+1 ');
                $sth->execute($CLDBID, $CLNAME, 1, $CLNAME) or die $DBI::errstr;;
                $sth->finish();
        }
}
## disconnect from database
$dbh->disconnect();

                


               
