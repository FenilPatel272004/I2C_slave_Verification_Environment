#!/usr/bin/perl
use strict;
use warnings;

# Output file
my $output_file = "merged_output.txt";
open(my $out_fh, '>', $output_file) or die "Cannot open $output_file: $!";

# Folders to scan
my @dirs = ("DUT", "COMPONENT", "TESTCASE");

# Files in main directory
my @files = ("testbench_top.sv", "i2c_pkg.sv");

# make final array of file names with relative path
foreach my $dir (@dirs){
	opendir(my $dh, $dir) or die "Cannot open directory: $!";
	my @dir_files = sort grep { -f "$dir/$_" && $_ !~ /^\./ } readdir($dh); # extract file name
	push(@files, map { "$dir/$_" } @dir_files); # add diractory name to each element
	closedir($dh);
}

# read each files form @files and write it to output_file
foreach my $file_name (@files){
	open (my $fh, '<', $file_name) or die $_;
	print $out_fh "Filename : $file_name\n\n";
	while(my $line = <$fh>){
		print $out_fh $line;
	}
	print $out_fh "\n\n/******************************/\n\n";
	close $fh;
}

close $out_fh;

