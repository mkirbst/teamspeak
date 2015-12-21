<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
        <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
        <title>moerbst.de TS3-Top10 </title>
        <link rel="stylesheet" href="css/style.css" type="text/css">
</head>

<body>

<div id="container">

        <table class="zebra">
    <caption><a href=http://moerbst.de>moerbst.de Teamspeak3 Camper Top10</a></caption>
                <thead>
                <tr>
                                <th>rank</th>
                                <th>name</th>
                                <th>TS3 server id</th>
                                <th>time</th>
            </tr>
                </thead>
        <tbody>
<?php
$COUNTER=1;

function secondsToTime($inputSeconds) {

    $secondsInAMinute = 60;
    $secondsInAnHour  = 60 * $secondsInAMinute;
    $secondsInADay    = 24 * $secondsInAnHour;

    // extract days
    $days = floor($inputSeconds / $secondsInADay);

    // extract hours
    $hourSeconds = $inputSeconds % $secondsInADay;
    $hours = floor($hourSeconds / $secondsInAnHour);

    // extract minutes
    $minuteSeconds = $hourSeconds % $secondsInAnHour;
    $minutes = floor($minuteSeconds / $secondsInAMinute);

    // extract the remaining seconds
    $remainingSeconds = $minuteSeconds % $secondsInAMinute;
    $seconds = ceil($remainingSeconds);

    // return the final array
    $obj = array(
        'd' => (int) $days,
        'h' => (int) $hours,
        'm' => (int) $minutes,
        's' => (int) $seconds,
    );
        $res= $days."d".$hours."h".$minutes."m";
        return $res;
//        return $days." Tage ".$hours." Stunden ";
}



// create database connection, credentials same as in perl script
$link = mysql_connect("127.0.0.1", "ts3queryuser", "passwd")
    or die("mysql connection error: " . mysql_error());
# echo "mysql connection successful";
mysql_select_db("ts3db") or die("could not select specified database");

// execute the mysql statement
$query = "SELECT CLNAME,CLDBID,Minutes FROM ts3top  WHERE clname NOT LIKE '%bot%' AND clname NOT LIKE  '%127.0.0.1%' ORDER BY Minutes DESC, CLDBID ASC";
$result = mysql_query($query) or die("query failed: " . mysql_error());

// print the output as html
while ($line = mysql_fetch_array($result, MYSQL_ASSOC)) {
    $n=0;
    echo "\t<tr>\n";

    echo "<td>".$COUNTER++."</td>";
    foreach ($line as $col_value) {
                                $n++;

        echo "\t\t<td>";

                                //count to 3. tab format only this value
        if($n == 3) {
                echo secondsToTime($col_value*60)." (".$col_value."min)";
        } else {
                echo $col_value;
                                }

        echo "</td>\n";
    }
    echo "\t</tr>\n";
}

// now free the result set
mysql_free_result($result);

// close connection
mysql_close($link);

?>

        </tbody>
        </table>
</div>

</body>
</html>


