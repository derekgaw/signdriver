#!/usr/bin/env perl
#
# Perl common chunks
#
use strict ;
use feature qw(say switch);

# use Data::Dumper;
# $Data::Dumper::Sortkeys = 1 ;

# SSL/LWP checks?
# $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME}=0;

#### work out where i am
# these variables can then be used to find config files
# and keep the code portable

# //Input a value 0 to 384 to get a color value.
# //The colours are a transition r - g -b - back to r

# foreach my $i ( 0 .. 384 ) {
#     wheel($i);
# }

# websafe and back is messy math because of the rounding of the INTS
# it is probably simpler to just make a lookup table

my @idxChan=(10,32,54,76,98,120);

# foreach my $c ( 0 .. 215 ) {
#     # use the index for forward and reverse
#     index2rgb( $c);
# }

websafe( 0,0,1);
websafe( 255,255,255);
websafe( 128,255,64);
index2rgb( 104 );

exit ;

# convert an int 0-215 to an RGB 1-127 value
sub index2rgb {
    my ( $idx ) = @_;
    my $mod ;

    #####
    # this is the compact version with less math

    $mod = $idx % 6 ;
    my $b = $idxChan[ $mod ];
    $idx -= $mod ;

    $mod = $idx % 36 ;
    my $g = $idxChan[$mod/6];
    $idx -= $mod ;

    my $r = $idxChan[$idx/36];

    say "idx2rgb( $r , $g , $b ) $idx";
    return ;


    #####
    # this is the verbose version, with intermediate values

    # peel off the modulo for each channel
    # quantised as 6 * 6 * 6
    my $bi = $idx % 6 ;

    my $tid = $idx - $bi ;
    my $gi = $tid % 36 ;

    # my $bi = ( $tid - $gi ) / 36 ;
    my $ri = ( $tid - $gi );

    my $b = $idxChan[$bi];
    my $g = $idxChan[$gi/6];
    my $r = $idxChan[$ri/36];

    # $c == 0 and $quantCol = 0 ;
    # $c >= 250 and $quantCol = 127 ;

    say "idx2rgb( $r , $g , $b ) [$ri , $gi , $bi ] $idx";
}

sub websafe {
    # calc a quantised color, with each channel 0-127 (7 bit)
    # /44 seems to divide nicely
    my ( $r , $g , $b )=@_;
    my $ri = int($r/44)*36 ;
    my $gi = int($g/44)*6;
    my $bi = int($b/44);
    my $color = $ri + $bi + $gi ;

    say "websafe( $r , $g , $b ) [$ri , $gi , $bi ] $color";
}

####

# wheel just rotates around 384 values r->g->b ..->r
sub wheel {
    my ( $WheelPos ) = @_ ;
    my ( $r , $g , $b );
    my $rem = int ( $WheelPos / 128 ) ;

    if ( $rem == 0 ) {
          $r = 127 - $WheelPos % 128;
          $g = $WheelPos % 128;
          $b = 0;
    }
    if ( $rem == 1 ) {
          $g = 127 - $WheelPos % 128;
          $b = $WheelPos % 128;
          $r = 0;
        }
    if ( $rem == 2 ) {
          $b = 127 - $WheelPos % 128;
          $r = $WheelPos % 128;
          $g = 0;
  }

  say "$r $g $b" ;

}
