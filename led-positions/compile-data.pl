#!/usr/bin/env perl
#
# Perl common chunks
#
use strict ;
use feature qw(say switch);

use Data::Dumper;
$Data::Dumper::Sortkeys = 1 ;

# SSL/LWP checks?
# $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME}=0;

#### work out where i am
# these variables can then be used to find config files
# and keep the code portable

use FindBin qw($Bin $Script);
my ($BASE,$NAME)=($Bin,$Script) ;

use lib "lib" ;
use lib "$FindBin::Bin" ;
use lib "$FindBin::Bin/lib" ;

# auto include help|?' => pod2usage(2)
# need 'SYNOPSIS' and 'OPTIONS'
use Getopt::Long qw(:config auto_help);

my $DEBUG ;
my $NOOP ;

GetOptions (
#     "V|version"    => sub { print "\n$ID\n$REV\n\n"; exit ; },
    "d=s"       => \$DEBUG,
    "n"       => \$NOOP,
);

unless ( @ARGV ) {
    die "Usage: $NAME <led-coords.csv>\n";
}

# declare a _schema in the dat that describes the json
# so anyone can understand the file if they see it

my $data = {
    _schema => {
        pixels => {
            _desc => "the raw data for the pixels, indexed by ID",
            xpo => "X position scaled for processing pixels, INTEGER",
            ypo => "Y position scaled for processing pixels, top left == 0",
            letter => "Which letter this pixel belongs to",
            id => "the pixel In in the complete string",
            lpo => "position of this pixel in a letter // not used, see the index",
        },
        index => {
            _desc => "various indexes that point back to a pixel ID",
            letter => {
                _desc => "the pixel IDs for a letter, sorted by the 'lpo' sequence, (hard to invert back to the pixel records)",
            }
        }
    },
    config => {
        xscale => 20,
        yscale => 24,
        offsetx => 20,
        offsety => 20,

    }
};

# defined here to keep it out of the config
my $letterSequence = {
    A=>[
        [80,131],[62,79]
        ],
    E=>[
        [61,61],[132,155],[20,60]
        ],
    Z=>[
        [202,208],[1,19],[157,201]
        ]
};

use JSON ;
my $json = JSON->new->canonical->pretty;

my $maXx ;
my $maXy ;


# open(my $fh, "<", "input.txt")
while (<>) {
    next unless /^\d+/; # skip header
    chomp ;
    s/\r$//;
    s/-//g;

    my ( $id , $x ,$y , $letter ) = split(/,/);

    # say " ( $id , $x ,$y , $letter ) $_ ";

    #  scale up the data, convert to INTS
    my $xp = int( $x * $data->{config}{xscale} );
    my $yp = int( $y * $data->{config}{yscale} );

    $maXy = $yp if $yp >= $maXy;
    $maXx = $xp if $xp >= $maXx;

    # store some records
    $data->{pixels}{$id} = {
        xpo => $xp,
        ypo => $yp,
        letter => $letter,
        id => $id,
    }

    # index some records??
    # $data->{index}{letter}{$letter}{} = {

}

# compile in the letter sequence, this can become an index to the
# lpo data, and we need to remove any DEAD pixels
foreach my $l ( keys %{ $letterSequence }) {
    my @pairs = @{ $letterSequence->{$l} };
    my @seq ;
    foreach my $pair ( @pairs ) {
        # but force strings...
#         push @seq , ( $pair->[0] .. $pair->[1] );
        push @seq , map { "$_" } ( $pair->[0] .. $pair->[1] );
    }
    # say "@seq" ;

    # BUT, we still need to walk this sequence and check if any of these
    # are dead pixels, (won't be assigned to a letter)
    my @nseq ;
    foreach my $id ( @seq ) {
        # my $l = $data->{pixels}{$id}{letter};
        # say "check ID : $id : $l ";
        push @nseq , $id if $data->{pixels}{$id}{letter};
    }

    $data->{index}{letter}{$l} = \@nseq ;
    $data->{config}{length}{$l} = $#nseq ;

}

# print Dumper ( $data );
# exit ;

# store the viewport max
$data->{config}{maXx} = $maXx + ( $data->{config}{offsetx} * 2 );
$data->{config}{maXy} = $maXy + ( $data->{config}{offsety} * 2 );;

# now invert the Y axis and offset the pixels we care about
foreach my $id ( keys %{ $data->{pixels} } ) {
    my $rec = $data->{pixels}{$id};
    if ( $data->{pixels}{$id}{letter} ) {
        $rec->{xpo} += $data->{config}{offsetx};
        $rec->{ypo} *= -1 ;
        $rec->{ypo} += ( $maXy + $data->{config}{offsety}) ;
    }
}

# and the original sequence ;
my @os = sort {$a <=> $b} keys %{ $data->{pixels} } ;
$data->{index}{letter}{'orig'} = \@os ;

my $jdata = $json->encode($data);
say $jdata ;
