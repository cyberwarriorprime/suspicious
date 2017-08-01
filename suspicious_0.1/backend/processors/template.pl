#!/usr/bin/perl -w
#
# Script:  template.pl
# Object:  Used to format data for suspicious frontend
#
# Date:    Sun Feb 15 14:11:45 CET 2016
# Author:  freddy@linuxtribe.fr


use strict;
use lib 'lib/';
use COLLECTOR;

my $tag = $ARGV[0];
my $hist_dir = $ARGV[1];

my %stats;

my ($country,$region,$city,$lon,$lat);

while(<STDIN>) {
    if (/[YOUR REGEXP]/) {

	[INIT YOUR LOCAL VARS]
	[$year $month $day $hour $min required]
	[$ip $service $timelog required]

# MAIN STATS UPDATE

       unless(defined($stats{$ip}{$service})) {
         my %new_hash;
         $stats{$ip}{$service} = \%new_hash;
         $stats{$ip}{$service}{'occurences'} = 1;
         $stats{$ip}{$service}{'timelog'} = "$timelog<br/>";
       } else {
         $stats{$ip}{$service}{'occurences'} += 1;
         $stats{$ip}{$service}{'timelog'} .= "$timelog<br/>";
       }

# TIMELINED CSV TREE UPDATE

       unless(-f "$hist_dir/$year/$month/$day/suspicious_$hour"."h00.csv" ) {
         system("mkdir -p \"$hist_dir/$year/$month/$day\"");
         system("echo \"host,ip,service,occurences,country,region,city,lat,lon,timelog\" > \"$hist_dir/$year/$month/$day/suspicious_$hour"."h00.csv\"");
       }
       unless(check_log("$hist_dir/$year/$month/$day/suspicious_$hour"."h00.csv",$ip,$tag,$service,$timelog)) {
         ($country,$region,$city,$lat,$lon) = get_geodata($ip);
         system("echo \"$tag,$ip,$service,$stats{$ip}{$service}{'occurences'},$country,$region,$city,$lat,$lon,$timelog\" >> \"$hist_dir/$year/$month/$day/suspicious_$hour"."h00.csv\"");
       }
    }
}

# MAIN STATS OUTPUT

foreach my $ip (keys %stats) {
   ($country,$region,$city,$lat,$lon) = get_geodata($ip);
   foreach my $service (keys %{$stats{$ip}}) {
       print "$tag,$ip,$service,$stats{$ip}{$service}{'occurences'},$country,$region,$city,$lat,$lon,$stats{$ip}{$service}{'timelog'}\n";
   }
}

sub check_log {
  my ($f,$ip,$c,$s,$t) = @_;

# ugly but efficient

  my @r = `grep $ip "$f" |grep "$t" |grep "$s" |grep "$c"`;

  return(0) if ($#r < 0);
  return(1);
}

sub get_geodata {
   my $ip = $_[0];

   my ($C,$r,$c,$la,$lo);
   my $geocmd = COLLECTOR::build_cmd('geoiplookup');
   my @raw = split(',',`$geocmd $ip`);

   foreach (@raw) {
     s/^[\s\t]*//;
     s/[\s\t]*$//;
     s/N\/A/unknown/g;
     s/Rev \d+: (\w+)/$1/;
     s/City of,/City of/;
   }

   if (defined($raw[6])) {
     ($C,$r,$c,$la,$lo) = ($raw[1],$raw[3],$raw[4],$raw[6],$raw[7]);
   }

   return($C,$r,$c,$la,$lo);
}
