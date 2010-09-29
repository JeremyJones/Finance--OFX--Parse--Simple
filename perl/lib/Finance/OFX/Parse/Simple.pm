package Finance::OFX::Parse::Simple;
use warnings;
use strict;

=head1 NAME

Finance::OFX::Parse::Simple - Parse a simple OFX file or scalar

=head1 VERSION

Version 0.06

=cut

our $VERSION = '0.06';

=head1 SYNOPSIS

   use Finance::OFX::Parse::Simple;

   my $parser = Finance::OFX::Parse::Simple->new;

   my $data_from_file     = $parser->parse_file("myfile.ofx"); # returns a reference to a list of hash references

   my $data_from_scalar   = $parser->parse_scalar($ofx_data); 

=head1 METHODS

=head2 new

Create a new parser object.

=cut

sub new
{
    my $class = shift;
    my $self  = bless({}, ref($class) || $class);
    return $self;
}

=head2 parse_file

Takes a filename as an argument, slurps the file into memory, parses
it and returns a reference to a list of hash references. Each hash
reference contains two keys: 'account_id' which is the account number,
and 'transactions' which is a reference to a list of hash references,
each containing details for a single transaction.

Returns false if no filename was provided, the file is not a plain
file, or the file is not openable.

=cut

sub parse_file
{
    my $self = shift;
    my $file = shift or return;

    -f($file) or return;

    my $contents = do
    {
	open my $fh, "<", $file or return;
	local $/; 
	my $c = <$fh>;
	close $fh;

	$c;
    };
    return $self->parse_scalar($contents);
}

=head2 parse_scalar

Takes a scalar as an argument containing OFX data. Returns a reference
to a list of hash references. Each hash reference contains two keys:
'account_id' which is the account number, and 'transactions' which is
a reference to a list of hash references, each containing details for
a single transaction.

Returns false if no non-empty scalar is provided.

=cut

sub parse_scalar
{
    my $self     = shift;
    my $ofx      = shift or return;
    my @results  = (); # to be returned
    
    my $decimal_separator = $ENV{MON_DECIMAL_POINT} || do
    {
	eval 'use POSIX qw(locale_h)';
	my $loc = eval {localeconv()} || {};
	$loc->{mon_decimal_point} || $loc->{decimal_point} || '.';
    };

  transaction_group:
    while ($ofx =~ m!(<STMTTRNRS>(.+?)</STMTTRNRS>)!sg)
    {
	my ($all,$statements) = ($1,$2);

	my $this = { account_id => undef, transactions => [] };
	
	my $account_id = do
	{
	    my $aa = 0;
	    
	    if ($all =~ m:<ACCTID>([^<]+?)\s*<:s)
	    {
		$aa = $1;
	    }
	    $aa;
	}
	or do {warn "No ACCTID found"; next transaction_group};

	$this->{account_id} = $account_id;

	while ($statements =~ m/<BANKTRANLIST>(.+?)<\/BANKTRANLIST>/sg)
	{
	    my $trans = $1;

	    while ($trans =~ m/<STMTTRN>(.+?)<\/STMTTRN>/sg)
	    {
		my $s = $1;
		
		my ($y,$m,$d) = $s =~ m/<DTPOSTED>(\d\d\d\d)(\d\d)(\d\d)/s ? ($1,$2,$3) : ('','','');

 		my $amount = undef;

		if ($s =~ m/<TRNAMT>\s*([-+])?\s*        # positive-negative sign $1
		    (?:(\d+)                             # whole numbers $2
		     (?:\Q$decimal_separator\E(\d\d)?)?  # optionally followed by fractional number $3
		     |                                   # or
		     \Q$decimal_separator\E(\d\d))       # just the fractional part $4
		    /sx)
		{
		    my $posneg = $1 || "";
		    my $whole  = $2 || 0;
		    my $frac   = $3 || $4 || 0;

		    $amount = sprintf("%.2f", ($whole + ($frac / 100)) * (($posneg eq '-') 
									  ? -1 
									  : 1));
		}

		my $fitid = $s =~ m/<FITID>([^\r\n<]+)/s ? $1 : '';

		my $trntype = $s =~ m/<TRNTYPE>([^\r\n<]+)/s ? $1 : '';

		my $checknum = $s =~ m/<CHECKNUM>([^\r\n<]+)/s ? $1 : '';

		my $name = $s =~ m/<NAME>([^\r\n<]+)/s ? $1 : '';
		my $memo = do
		{
		    my $w = "";
		    if ($s =~ m/<MEMO>([^\r\n<]+)/s)
		    {
			$w = $1;
		    }
		    $w;
		};
		push @{$this->{transactions}}, {amount => $amount, date => "$y-$m-$d",
						checknum => $checknum, trntype => $trntype,
						fitid  => $fitid,  name => $name, memo => $memo};
	    }
	}
	push @results, $this;
    }
    return \@results;
}

=head1 WARNING

From Finance::Bank::LloydsTSB:

This is code for online banking, and that means your money, and that
means BE CAREFUL. You are encouraged, nay, expected, to audit the
source of this module yourself to reassure yourself that I am not
doing anything untoward with your banking data. This software is
useful to me, but is provided under NO GUARANTEE, explicit or implied.

=head1 AUTHOR

Jeremy Jones, C<< <jjones at cpan.org> >>

=head1 BUGS

This module is intended to be fit-for-purpose, that purpose being simple parsing of real-world OFX files
as provided for download by online banking systems. For more thorough and better treatment of your OFX 
data see Finance::OFX::Parse.

Please report any bugs or feature requests to C<bug-finance-ofx-parse-simple at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Finance-OFX-Parse-Simple>. 

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Finance::OFX::Parse::Simple

The latest version of this module is available on Github:

    http://github.com/JeremyJones/Finance--OFX--Parse--Simple

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Finance-OFX-Parse-Simple>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Finance-OFX-Parse-Simple>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Finance-OFX-Parse-Simple>

=item * Search CPAN

L<http://search.cpan.org/dist/Finance-OFX-Parse-Simple/>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2009-10 Jeremy Jones, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Finance::OFX::Parse::Simple
