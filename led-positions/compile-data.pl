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

# declare a _schema in the data that describes the json
# so anyone can understand the file if they see it

my $data = {
    _schema => {
        pixels => {
            _desc => "the raw data for the pixels, indexed by ID",
            xpo => "X position scaled for processing pixels, INTEGER",
            ypo => "Y position scaled for processing pixels, top left == 0",
            letter => "Which letter this pixel belongs to",
            id => "the pixel position in the complete string",
            lpo => "position of this pixel in a letter // not used, see the index",
        },
        index => {
            _desc => "various indexes that point back to a pixel ID",
            letter => {
                _desc => "the pixel IDs for a letter, sorted by the 'lpo' sequence, (hard to invert back to the pixel records)",
            },
            wipe => {
                _desc => "X & Y pixel wipes",
                x => {
                    _desc => "array of X L-R pixel slices",
                },
                y => {
                    _desc => "array of Y T-B pixel slices",
                }

            },

        }
    },
    config => {
        xscale => 20,
        yscale => 24,
        offsetx => 20,
        offsety => 20,
        xslices => 30,
        yslices => 20,
        headerFile => 'signCoords.h',
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

my $maxX ;
my $maxY ;


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

    $maxY = $yp if $yp >= $maxY;
    $maxX = $xp if $xp >= $maxX;

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

# print Dumper ( $data->{pixels} );
# exit ;

# store the viewport max, mins
$data->{config}{minX} = $maxX;
$data->{config}{minY} = $maxY;
$data->{config}{maxX} = $maxX + ( $data->{config}{offsetx} * 2 );
$data->{config}{maxY} = $maxY + ( $data->{config}{offsety} * 2 );;

# now invert the Y axis and offset the pixels we care about
# also calculate the slice position

foreach my $id ( sort{ $a<=>$b} keys %{ $data->{pixels} } ) {
    my $rec = $data->{pixels}{$id};
    # print Dumper ( $rec );

    if ( $data->{pixels}{$id}{letter} ) {
        # calculate the slice position
        my $x = $rec->{xpo};
        my $y = $rec->{ypo};
        my $xs = int($x / $data->{config}{minX} * $data->{config}{xslices});
        my $ys = int($y / $data->{config}{minY} * $data->{config}{yslices});
        push @{ $data->{index}{wipe}{x}[$xs] } , $id ;
        push @{ $data->{index}{wipe}{y}[$ys] } , $id ;
        # say "ID $id : x[$x] xs[$xs]";

        # do the offset
        $rec->{xpo} += $data->{config}{offsetx};
        $rec->{ypo} *= -1 ;
        $rec->{ypo} += ( $maxY + $data->{config}{offsety}) ;

    }
}

# and the original sequence ;
my @os = sort {$a <=> $b} keys %{ $data->{pixels} } ;
$data->{index}{letter}{'orig'} = \@os ;

##################
# now write out all the data we have

my $jdata = $json->encode($data);
say $jdata ;

##################
# compile and generate a header file for arduino
# int lSeq[][]={{}}
open(my $hed, ">", $data->{config}{headerFile});
select $hed ;

# all sequences are zero based, so subtract 1 from every LED id
# using map functions

# we're also storing these as bytes, so the values have to be < 256

say "// LED arrays for each letter";
say "byte lSeq[][210]={";
foreach my $l ( keys %{ $data->{index}{letter} }) {
    next if $l eq 'orig';

    my @seq = @{ $data->{index}{letter}{$l} };
    map { $_ -= 1 } @seq ;


    my $len = @seq ;
    # say "  {" . join(",", $len , @{ $data->{index}{letter}{$l} } ) . "},";
    say "  // sequence : letter $l";
    say "  {" . join(",", $len , @seq ) . "},";
}
say "  {}";
say "};";

# print Dumper ( $data->{index}{wipe} );

# now index,sort and comile the wipes
say "// L-R slices, wipe right";
say "byte wipex[][20]={";
my $numwx = @{ $data->{index}{wipe}{x} };
say "  {1,$numwx},";
foreach my $wx ( @{ $data->{index}{wipe}{x} } ) {
    unless ( $wx ) {
        say "  {0,0},"; # handle undef/null
        next ;
    }

    # map to zero based
    my @seq = @{ $wx };
    map { $_ -= 1 } @seq ;
    my $len = @seq ;
    say "  {" . join(",", $len, @seq ) . "},";

    # my $len =  @{ $wx };
    # say "  {" . join(",", $len, @{ $wx } ) . "},";
}
say "  {0,0}";
say "};";

say "// T-B slices, wipe down";
say "byte wipey[][30]={";
my $numwy = @{ $data->{index}{wipe}{y} };
say "  {1,$numwy},";
foreach my $wy ( @{ $data->{index}{wipe}{y} } ) {
    unless ( $wy ) {
        say "  {0,0},"; # handle undef/null
        next ;
    }

    # map to zero based
    my @seq = @{ $wy };
    map { $_ -= 1 } @seq ;
    # map { $_ = sprintf("0x%X", $_) } @seq ;
    my $len = @seq ;
    say "  {" . join(",", $len, @seq ) . "},";

    # my $len =  @{ $wy };
    # say "  {" . join(",", $len , @{ $wy } ) . "},";
}
say "  {0,0}";
say "};";
