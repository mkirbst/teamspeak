#!/usr/bin/perl
##
## Download TableSort.js from http://www.j-berkemeier.de/TableSort.html and put this to your web directory where the html output resides
## call this script every few minutes to create actual html output page, i recommend nice -n 19 script
## and dont forget: im no webdesigner, so all my websites are ugly ;)

# output looks like: https://raw.githubusercontent.com/mkirbst/teamspeak/master/pic-ts3top10detailed.png

use strict;
use Net::Telnet;
use DBI;
use POSIX qw(strftime);


# mysql variables
my $DB_DATABASE = "ts3db";
my $DB_USERNAME = "DBUSER";
my $DB_PASSWORD = "DBPWD";
my $RANK = 1;


## set HTML-File output path here - CHECK FILE WRITE PERMISSION FOR THIS SCRIPT!!
# my $OUTFILE="/var/www/moerbstde/top10test.html";

#### open connection to database
my ($db_user, $db_name, $db_pass) = ($DB_USERNAME, $DB_DATABASE, $DB_PASSWORD);
my $dbh = DBI->connect("DBI:mysql:database=$db_name", $db_user, $db_pass);


## Sort by most minutes in first, then by teamspeak db id
my $sth = $dbh->prepare('SELECT * FROM ts3top ORDER BY Minutes DESC, CLDBID ASC');
$sth->execute() or die $DBI::errstr;;

#mysql> select * from ts3top;
#+--------+-----------------------+---------+------------+------------+------------+-----------------+
#| CLDBID | CLNAME                | Minutes | CLCREATED  | CLLASTCON  | CLCONCOUNT | CLLASTIP        |
#+--------+-----------------------+---------+------------+------------+------------+-----------------+
#|      2 | marcel_pc             |   25590 | 1415314641 | 1417991665 |         50 | ***.101.16.***  |
#|      3 | Dr_Devil              |   55247 | 1415315910 | 1417919855 |         19 | ***.18.216.***  |
#|      4 | Lia                   |   13379 | 1415316164 | 1417971296 |         10 | ***.210.10.***  |

##open output file
my $filename = '/var/www/moerbstde/top10.html';
open(my $fh, '>', $filename) or die "Could not open file '$filename' $!";

## documentation  TableSort.js: http://www.j-berkemeier.de/TableSort.html

print $fh "<!DOCTYPE html>"."\n";
print $fh "<HTML>"."\n";
print $fh "     <HEAD>"."\n";
print $fh "             <META  http-equiv=\"refresh\" content=\"60\" charset=\"UTF-8\">"."\n";
print $fh "             <script type=\"text/javascript\" src=\"TableSort.js\"></script>"."\n";
print $fh "             <link rel=\"stylesheet\" href=\"css/style.css\" type=\"text/css\">"."\n";
print $fh "     </HEAD>"."\n";
print $fh "     <BODY>"."\n";
print $fh       "<div id=\"container\">"."\n";
print $fh "             <TABLE class=\"sortierbar\" border=\"1\">"."\n";
print $fh "                     <THEAD>"."\n";
print $fh "                             <TR>"."\n";
print $fh "                                     <TH CLASS=\"sortierbar vorsortiert+\">Platz"."</TH>"."\n";
print $fh "                                     <TH CLASS=\"sortierbar\">Name"."</TH>"."\n";
print $fh "                                     <TH CLASS=\"sortierbar\">Teamspeak-ID"."</TH>"."\n";
print $fh "                                     <TH CLASS=\"sortierbar\">Zeit[Minuten]"."</TH>"."\n";
print $fh "                                     <TH CLASS=\"sortierbar\">Zeit[WeeksDaysHoursMins]"."</TH>"."\n";
print $fh "                                     <TH CLASS=\"sortierbar\">erster Connect"."</TH>"."\n";
print $fh "                                     <TH CLASS=\"sortierbar\">letzter Connect"."</TH>"."\n";
print $fh "                                     <TH CLASS=\"sortierbar\">Verbindungen"."</TH>"."\n";
print $fh "                             </TR>"."\n";
print $fh "                     </THEAD>"."\n";
print $fh "                     <TBODY>"."\n";
while (my @data = $sth->fetchrow_array()) 
{
        #       print($RANK++." ".$CLNAME." ".$CLDBID." ".$Minutes." ".$CLCREATED." ".$CLLASTCON." ".$CLCONCOUNT." ".$CLLASTIP."\n");

        my $tmpmins = $data[2];
        my $weeks = 0;
        my $days = 0;
        my $hours = 0;
        while ($tmpmins > 10080){
                $tmpmins -= 10080;
                $weeks++;
        }
        while ($tmpmins > 1440){
                $tmpmins -= 1440;
                $days++;
        }
        while ($tmpmins > 60){
                $tmpmins -= 60;
                $hours++;
        }

        my $prettyminutes = sprintf("%.4iw%.1id%.2ih%.2im", $weeks, $days, $hours, $tmpmins );
        ####end prettyminutes


        my $t0 = "";
        if($data[3] > 1412892000)       ## export only valid dates after 10.10.2014 00:00:00 
        {
                $t0 = strftime("%d.%m.%Y %H:%M", localtime($data[3]));  # Doku zu TableSort.js beachten damit richtig sortiert wird !!
        } else  {
                $t0 = "";
        }


        my $t1 = "";
        if($data[4] > 1412892000)       ## export only valid dates after 10.10.2014 00:00:00 
        {
                $t1 = strftime("%d.%m.%Y %H:%M", localtime($data[4]));  # Doku zu TableSort.js beachten damit richtig sortiert wird !!
        } else  {
                $t1 = "";
        }


        my $tmpline = "                                 <TR><TD>".$RANK++."</TD><TD>".$data[1]."</TD><TD>".$data[0]."</TD><TD>".$data[2]."</TD><TD>".$prettyminutes."</TD><TD>".$t0."</TD><TD>".$t1."</TD><TD>".$data[5]."</TD></TR>\n";
        print $fh $tmpline;
}
print $fh "                     </TBODY>"."\n";
print $fh "             </TABLE>"."\n";
print $fh "             </DIV>"."\n";
print $fh "     </BODY>"."\n";
print $fh "</HTML>\n";

close $fh;

## close db connection
$sth->finish();
$dbh->disconnect();
m@mk:~/skripte$
