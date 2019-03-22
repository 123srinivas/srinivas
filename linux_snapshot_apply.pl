#!/usr/bin/perl

use strict;
use Getopt::Long;

my $autoy;
my $p_fetch;
my $getlist;
my $linux_major;
my $linux_version;
my $lnx_version;
my $snapshot;
my $snapshot_list;
my $bit_level;
my $patch_type;
my $repo1;
my $repo2;
my $trsh;
my $snapshot_url;
my $snapshot_file;
my $port     = 443;   
my $devFlag  = 0;
my $hostname = `uname -n`; chomp($hostname);

GetOptions(
	"qa|dev|d"              => \$devFlag,
	"list|l"                => \$getlist,
	"bundle|b|snapshot|s=s" => \$snapshot,
	"set|type|t=s"        => \$patch_type,
	"yes_auto|y"            => \$autoy, 
	"port|p:i"              => \$port
);

## Check we are running as root
if ( $> ) {
	die "$0 must run as root\n";
}

## Fix capitalization
$snapshot   = uc($snapshot);
$patch_type = uc($patch_type) if ($patch_type =~ /both/i);

## Catch a break
$SIG{'INT'} = sub {
	print "CNTL-C detected!  Cleaning up..\n";
	print "Removing snapshots from yum.repos.d\n";
	system ("rm $repo1 $repo2");
	print "Moving old snapshot repos back into /etc/yum.repos.d\n";
	system ("mv /var/tmp/snapshot_repos/Q*.repo /etc/yum.repos.d/ > /dev/null 2>&1 ");
	system ("mv /var/tmp/snapshot_repos/CURRENT*.repo /etc/yum.repos.d/ > /dev/null 2>&1 "); ## Legacy
	system ("mv /var/tmp/snapshot_repos/cel-patchbundle*.repo /etc/yum.repos.d/ > /dev/null 2>&1 "); ## Legacy
	if ($port != 443) {
		system ("cp -p /etc/yum.repos.d/bak/*.repo /etc/yum.repos.d/ > /dev/null 2>&1 ");
	}
	exit 1;
} ;

sub usage {
	my $msg = shift;	
	print ("\n");
	print ("Usage: $0 [--list|-l] --snapshot|s <snapshot> --type|t <type> [--yes_auto|y] [--qa|dev|d] --port|p <alternate port number>\n\n");
	print ("$msg\n\n") if ($msg);
	exit 1;
}

unless (($getlist) || ($snapshot)) {
	usage("ERROR :: No snapshot specified.  Use [--list] to list the snapshots available for your OS.");
}

if (($getlist) && ($snapshot)) {
	usage("ERROR :: Unable to apply patches [--snapshot] and list snaphots [--list] at the same time");
}

if ($port == 0) {
	usage("ERROR :: Please specify a valid port number when using [--port] option. Use this option only if you are using ssh tunneling (Sim Dmz/Dmz/Protected) and need to specify an alternate port other than port 80");
}

## Providing python preferred, but selinux doesn't like this
my $yum_cmd    = "/usr/bin/python /usr/bin/yum";
my $selinx_chk = `/usr/sbin/getenforce`; chomp($selinx_chk);
if ( $selinx_chk =~ /Enforcing/i ) {
	print "INFO :: SELinux enforcing detected.\n";
	$yum_cmd = "/usr/bin/yum";
}

## Clean yum first.
print ("INFO :: Cleaning yum with 'yum clean all'...\n");
my $yum_clean = `$yum_cmd clean all`;
my $yum_cexit = $?;
if ($yum_cexit != 0 ) {
	print ("ERROR :: Yum clean up failed. Fix this and re-run the script.\n\n");
	exit 1;
}


## Get the bit level.
my $uname = `/bin/uname -a`;
if ($uname =~ /x86_64/) {
	$bit_level = "x86_64";
} else {
	$bit_level = "i386";
}

## Get the OS Major
open (SPROF, "/etc/system-profile") || die "Couldn't open /etc/system-profile.";
while (<SPROF>) {
	if (/^version/) {
		($trsh, $lnx_version) = split;

		if ($lnx_version =~ /centos/i) {
			$linux_major = 'centos';
		} else {
			$linux_major = 'rhel';
		}
		
		# Loop though known OS's. This will have to update if we screw with the later versions.
		if ($lnx_version =~ /5\.5|5\.3|5\.9/) {
			$linux_major .= "5";
		} elsif ($lnx_version =~ /5\.0/) {
			$linux_major .= "4";
		} elsif ($lnx_version =~ /6\./) {
			$linux_major .= "6";
		} elsif ($lnx_version =~ /7\./) {
			$linux_major .= "7";
		} elsif ($lnx_version =~ /8\./) {
			$linux_major .= "8";
		}
	}
}

print ("\n");
print ("INFO :: Hostname               : $hostname\n");
print ("INFO :: System Profile version : $lnx_version\n");
print ("INFO :: Linux major version    : $linux_major\n");
print ("INFO :: Bit Level detected     : $bit_level\n");
print ("INFO :: Using port             : $port\n"); 
print ("INFO :: Patching Environment   : " . ($devFlag ? 'Dev [quality assurance]' : 'Prod [released]') . "\n");
system ("mkdir -p /etc/yum.repos.d/bak; cp -p /etc/yum.repos.d/*.repo /etc/yum.repos.d/bak/ > /dev/null 2>&1");

## Convert to dev if needed.
if ($devFlag) {
	$p_fetch = "https://wwwin-repomgmt.cisco.com:$port/repos/snapshots/qa/";
} else {
	$p_fetch = "https://wwwin-repomgmt.cisco.com:$port/repos/snapshots/released/";
}

if ($getlist || $snapshot eq 'CURRENT') {

	my $response = browser ($p_fetch . $linux_major . "/");
	my @oslist   = split $/, $response;

	foreach (@oslist) {
		my @searcher = split "\"", $_;
		foreach (@searcher) {
			if (/^Q/) {
				my $tmp = $_;
				$tmp =~ s#/##g;
				my ($q,$fy) = split(/FY/, $tmp);
				$snapshot_list->{ $fy.$q } = $tmp;
			}
		}
	}

	my @tmp = sort keys %{$snapshot_list};
	my $current = $tmp[-1];

	if ($getlist) {
		## List of available patches.
		print ("\n");
		print ("Snapshots available for your OS:\n");
        
		foreach my $key (sort keys %{$snapshot_list}) {
			my $snapshot     = $snapshot_list->{$key};
			my $latest_snap  = $snapshot_list->{$current};
			my $response     = browser ($p_fetch . $linux_major . "/" . $snapshot . "/" . $bit_level . "/");
			my @snapshotlist = split $/, $response;
			$_ =~ s/\///g;
			if ($snapshot eq $latest_snap) {
				print ("\nSnapshot: $snapshot (Latest)\n");
			} else {
				print ("\nSnapshot: $snapshot\n");
			}

			foreach (@snapshotlist) {
				my @searcher = split "\"", $_;
				foreach (@searcher) {
					if ((/^reboot/) || (/^nonreboot/)) {
						$_ =~ s/\///g;
						print "    Type: $_\n";
					}
				}
			}
		}

		print ("\n");
		print ("Use \"$0 -s <SNAPSHOT> -t <TYPE>\" to apply a snapshot. You may use \"-t BOTH\" to apply both reboot and nonreboot.\n\n");
	}

	if ($snapshot eq 'CURRENT') {
		$snapshot = $snapshot_list->{$current};
	}
}

## Apply snapshot
if ($snapshot) {
	if (! $patch_type) {
		usage("ERROR :: No patch set selected. Use [--snapshot] and [--type] to apply a snapshot. You may use [--type BOTH] to apply both reboot and nonreboot");
		exit 1;
	}

	print ("\n");
	print ("Processing with: Snapshot [$snapshot] and Type [$patch_type]\n\n");

	if ($patch_type =~ /BOTH/i) {
		## Pull all old patch snapshots out.
		print ("Moving any existing patch repos to /var/tmp/snapshot_repos\n");
		system ("mkdir -p /var/tmp/snapshot_repos");
		system ("mv /etc/yum.repos.d/Q*.repo /var/tmp/snapshot_repos > /dev/null 2>&1");
		system ("mv /etc/yum.repos.d/CURRENT*.repo /var/tmp/snapshot_repos > /dev/null 2>&1"); ## Legacy
		system ("mv /etc/yum.repos.d/cel-patchbundle*.repo /var/tmp/snapshot_repos > /dev/null 2>&1 "); ## Legacy

		for my $type ('nonreboot', 'reboot') {
			my $snapshot_url  = $p_fetch . $linux_major . "/" . $snapshot . "/" . $bit_level . "/" . $type . "/cisco-snapshot-$type.repo";

			if ($devFlag) {
				$snapshot_file = "/etc/yum.repos.d/$snapshot-snapshot-$type-dev.repo";
			} else {
				$snapshot_file = "/etc/yum.repos.d/$snapshot-snapshot-$type-prod.repo";
			}

			my $response = browser ($snapshot_url);
			if (! $response) {
				print ("\n");
				print ("Snapshot not found!\n");
				print ("URL: $snapshot_url\n");
				print ("Something is wrong with the snapshot URL. Please double check your snapshot.\n\n");
					
				print ("Moving old snapshots back into /etc/yum.repos.d\n");
				system ("mv /var/tmp/snapshot_repos/Q*.repo /etc/yum.repos.d/ > /dev/null 2>&1");
				system ("mv /var/tmp/snapshot_repos/CURRENT*.repo /etc/yum.repos.d/ > /dev/null 2>&1 "); ## Legacy
				system ("mv /var/tmp/snapshot_repos/cel-patchbundle*.repo /etc/yum.repos.d/ > /dev/null 2>&1 "); ## Legacy
				exit 1;
			}

			print ("Copying: $snapshot_url \nTo: $snapshot_file\n");
			curl ($snapshot_url, $snapshot_file);
			$repo1 = $snapshot_file if ($type eq 'nonreboot');
			$repo2 = $snapshot_file if ($type eq 'reboot');
		}	

	} else {
		## Pull only the old repo that you are replacing.
		print ("Moving '$patch_type' repos to /var/tmp/snapshot_repos\n");
		system ("mkdir -p /var/tmp/snapshot_repos");
		system ("mv /etc/yum.repos.d/Q*-$patch_type-*.repo /var/tmp/snapshot_repos > /dev/null 2>&1 ");
		system ("mv /etc/yum.repos.d/CURRENT*-$patch_type-*.repo /var/tmp/snapshot_repos > /dev/null 2>&1"); ## Legacy

		my $snapshot_url  = $p_fetch . $linux_major . "/" . $snapshot . "/" . $bit_level . "/" . $patch_type . "/cisco-snapshot-$patch_type.repo";

		if ($devFlag) {
			$snapshot_file = "/etc/yum.repos.d/$snapshot-snapshot-$patch_type-dev.repo";
		} else {
			$snapshot_file = "/etc/yum.repos.d/$snapshot-snapshot-$patch_type-prod.repo";
		}

		my $response = browser ($snapshot_url);
		if (! $response) {
			print ("\n");
			print ("Snapshot not found!\n");
			print ("URL: $snapshot_url\n");
			print ("Something is wrong with the snapshot URL. Please double check your snapshot.\n\n");
			
			print ("Moving old snapshots back into /etc/yum.repos.d\n");
			system ("mv /var/tmp/snapshot_repos/Q*.repo /etc/yum.repos.d/ > /dev/null 2>&1");
			system ("mv /var/tmp/snapshot_repos/CURRENT*.repo /etc/yum.repos.d/ > /dev/null 2>&1 "); ## Legacy
			system ("mv /var/tmp/snapshot_repos/cel-patchbundle*.repo /etc/yum.repos.d/ > /dev/null 2>&1 "); ## Legacy
			exit 1;
		}

		print ("Copying: $snapshot_url \n");
		print ("To: $snapshot_file\n");
		curl ($snapshot_url, $snapshot_file);
		$repo1 = $snapshot_file;

	}

	if ($port != 443) {
		my $cmd = q{perl -pi -e 's|(https://[^/:]+):?\d*/|$1:} . $port . q{/|' /etc/yum.repos.d/Q*.repo};
		system ("$cmd");
        }

	## Execute yum command
	my ($sec,$min,$hour,$mday,$mon,$year, $wday,$yday,$isdst) = localtime time;
	my $tee_output = "/var/tmp/$snapshot-yum-output-$hour.$min.log";
	if ($autoy) {
		$autoy = '-y';
	} 

	my $yum_exec = "$yum_cmd $autoy update --disablerepo=* --enablerepo=*reboot* --enablerepo=*base*";
	print ("\n\n");
	print ("Patch repo files in place, starting the yum installation\n");
	print ("Output is logged to: $tee_output\n\n");

	$|++;

	open (YUM_OUT, "$yum_exec|");
	open (TEE_OUT, "> $tee_output");
		
	while (sysread(YUM_OUT,$_,128)) {
		print TEE_OUT;
		print;
		print "Is this ok [y/N]: " if (/Total download size/ && ! $autoy);
	}
	close YUM_OUT;
	my $yum_exit = $?;
	if ($yum_exit != 0 ) {
		print ("\n");
		print ("Yum did not exit clean... Exit status: $yum_exit\n");
		print ("Removing bundles from yum.repos.d\n");
		system ("rm $repo1 $repo2");
		print ("Moving old bundles back into /etc/yum.repos.d\n");
		system ("mv /var/tmp/snapshot_repos/Q*.repo /etc/yum.repos.d/ > /dev/null 2>&1 ");
		system ("mv /var/tmp/snapshot_repos/CURRENT*.repo /etc/yum.repos.d/ > /dev/null 2>&1 "); ## Legacy
		system ("mv /var/tmp/snapshot_repos/cel-patchbundle*.repo /etc/yum.repos.d/ > /dev/null 2>&1 "); ## Legacy
		system ("cp -p /etc/yum.repos.d/bak/*.repo /etc/yum.repos.d/ > /dev/null 2>&1 ");
		print ("Patch script did not apply any bundles. Yum must complete successfully.  Please run the script again...\n\n");
     		exit 1;
	} 

	if (($patch_type eq "BOTH") || ($patch_type eq "reboot")) {
		## Hack to work oracleasm into the bundle if the reboot bundle is applied.
		my $oracleasm_chk = `rpm -qa | grep oracleasm-`;
		if ($oracleasm_chk ne "" ) {
			print "\nDetected oracleasm, running yum update for the oracleasm kernel rpm...\n";
			`$yum_cmd install oracleasm-* -y `;
			if ($? != 0 ) {
				print ("Yum update of oracleasm was not successful.  Please confirm that your oracleasm rpm matches your kernel version.  You will want to re-run this script until this command returns exit status 0.\n");
				print ("Exit Status:  $?\n\n");
				print ("Removing bundles from yum.repos.d\n");
				system ("rm $repo1 $repo2");
				print ("Moving old snapshots back into /etc/yum.repos.d\n");
				system ("mv /var/tmp/snapshot_repos/Q*.repo /etc/yum.repos.d/ > /dev/null 2>&1 ");
				system ("mv /var/tmp/snapshot_repos/CURRENT*.repo /etc/yum.repos.d/ > /dev/null 2>&1 "); ## Legacy
				system ("mv /var/tmp/snapshot_repos/cel-patchbundle*.repo /etc/yum.repos.d/ > /dev/null 2>&1 "); ## Legacy
		                system ("cp -p /etc/yum.repos.d/bak/*.repo /etc/yum.repos.d/ > /dev/null 2>&1 ");
				exit 1;
			}
		}
	}

        if ($port != 443) {
		system ("cp -p /etc/yum.repos.d/bak/*.repo /etc/yum.repos.d/ > /dev/null 2>&1;");
        }

	print ("\n\n");
	print ("Script has completed successfully.  The repo files are in place.  You may continue.\n\n");
}

sub curl {
	my ($url, $file) = @_;
	my $ck_code = `curl -s -o /dev/null -w "%{http_code}" --insecure $url`;
	if ( $ck_code ne '200' ) {
		print ("\nInvalid data provided\n");
		print ("URL invalid: $url\n");
		exit 1;
	}
	system("curl -s --insecure $url > $file");
}

sub browser {
	my ($url) = @_;
	## We can't assume all servers have LWP.
	my $out = `curl -s --insecure $url`;
	return $out;
}
