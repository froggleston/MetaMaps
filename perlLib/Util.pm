package Util;

use strict;
use File::Copy;
use List::Util qw/all/;
use Data::Dumper;

use taxTree;

sub copyMetaMapDB
{
	my $source = shift;
	my $target = shift;
	
	my @files_required = ('DB.fa', 'taxonInfo.txt');
	my @files_optional = ('selfSimilarities.txt');
	
	unless(-d $target)
	{
		mkdir($target) or die "Cannot mkdir $target";
	}
	
	foreach my $f (@files_required)
	{
		my $fP = $source . '/' . $f;
		my $tP = $target . '/' . $f;
		unless(-e $fP)
		{
			die "Source DB directory $source doesn't contain file $f";
		}
		copy($fP, $tP) or die "Couldn't copy $fP -> $tP"; 
	}	
	
	foreach my $f (@files_optional)
	{
		my $fP = $source . '/' . $f;
		my $tP = $target . '/' . $f;
		if(-e $fP)
		{
			copy($fP, $tP) or die "Couldn't copy $fP -> $tP"; 
		}
	}	 
 
	my @existing_files_taxonomy = glob($source . '/taxonomy/*');
	
	my @required_files_taxonomy = taxTree::getTaxonomyFileNames();
	
	die Dumper("Taxonomy files missing?", \@existing_files_taxonomy, @required_files_taxonomy) unless(all {my $requiredFile = $_; my $isThere = (scalar(grep {my $existingFile = $_; my $pattern = '/' . $requiredFile . '$'; my $isMatch = ($existingFile =~ /$pattern/); print join("\t", "'" . $existingFile . "'", "'" . $pattern . "'", $isMatch), "\n" if(1==0); $isMatch} @existing_files_taxonomy) == 1); warn "File $requiredFile missing" unless($isThere); $isThere} @required_files_taxonomy);
	
	my $target_taxonomyDir = $target . '/taxonomy/';
	unless(-d $target_taxonomyDir)
	{
		mkdir($target_taxonomyDir) or die "Cannot mkdir $target_taxonomyDir";
	}
	foreach my $f (@existing_files_taxonomy)
	{
		copy($f, $target_taxonomyDir) or die "Cannot copy $f into ${target}/taxonomy";
	}
}

sub getGenomeLength
{
	my $taxonID = shift;
	my $taxon_2_contig = shift;
	my $contig_2_length = shift;
	
	die unless(defined $contig_2_length);
	
	my $gL = 0;
	die "Cannot determine genome length for taxon ID $taxonID" unless(defined $taxon_2_contig->{$taxonID});
	
	my @contigIDs;
	if(ref($taxon_2_contig->{$taxonID}) eq 'ARRAY')
	{
		@contigIDs = @{$taxon_2_contig->{$taxonID}}
	}
	elsif(ref($taxon_2_contig->{$taxonID}) eq 'HASH')
	{
		@contigIDs = keys %{$taxon_2_contig->{$taxonID}}
	}
	else
	{
		die;
	}
	foreach my $contigID (@contigIDs)
	{
		die unless(defined $contig_2_length->{$contigID});
		$gL += $contig_2_length->{$contigID};
	}
	
	return $gL;
}	

sub mean
{
	my $s = 0;
	die unless(scalar(@_));
	foreach my $v (@_)
	{
		$s += $v;
	}
	return ($s / scalar(@_));
}

sub sd
{
	die unless(scalar(@_));
	my $m = mean(@_);
	my $sd_sum = 0;
	foreach my $e (@_)
	{
		$sd_sum += ($m - $e)**2;
	}
	my $sd = sqrt($sd_sum);
	return $sd;
}

sub readFASTA
{
	my $file = shift;	
	my $cut_sequence_ID_after_whitespace = shift;
	
	my %R;
	
	open(F, '<', $file) or die "Cannot open $file";
	my $currentSequence;
	while(<F>)
	{		
		my $line = $_;
		chomp($line);
		$line =~ s/[\n\r]//g;
		if(substr($line, 0, 1) eq '>')
		{
			if($cut_sequence_ID_after_whitespace)
			{
				$line =~ s/\s+.+//;
			}
			$currentSequence = substr($line, 1);
			$R{$currentSequence} = '';
		}
		else
		{
			die "Weird input in $file" unless (defined $currentSequence);
			$R{$currentSequence} .= uc($line);
		}
	}	
	close(F);
		
	return \%R;
}


1;
