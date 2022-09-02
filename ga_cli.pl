#!/usr/bin/perl
#===================================================================#
# Program => ga_cli.pl (In Perl 5.0)                  version 0.0.1 #
#===================================================================#
# Autor         => Fernando "El Pop" Romo        (pop@cofradia.org) #
# Creation date => 01/September/2022                                #
#-------------------------------------------------------------------#
# Info => This program is a CLI version of the Google Authenticator #
#         App. Read de conf file generated with the program         #
#         qr_to_ga_cli.pl and show the OTP from sites               #
#-------------------------------------------------------------------#
# This code are released under the GPL 3.0 License. Any change must #
# be report to the authors                                          #
#                 (c) 2021 - Fernando Romo                          #
#===================================================================#
use strict;
use Auth::GoogleAuth;
use Convert::Base32;
use Imager::QRCode;

# Text Colors
use constant {
    RESET    => "\033[0m",
    FG_RED   => "\033[31m",
    FG_GREEN => "\033[32m",
};

# Load config File
my %key_ring = do './ga_cli.conf';

# Show Green or Red Text if the timer change
sub semaphore {
    my ($seconds) = (localtime( time() ))[0];
    my $aux = $seconds % 30;
    my $color = FG_RED;
    if ($aux <= 25) {
       $color = FG_GREEN;
    }
    return $color;
}

# Show the OTP generated
foreach my $issuer (sort keys %key_ring) {
    my $auth = Auth::GoogleAuth->new({
           secret => "$key_ring{$issuer}{secret}",
           issuer => "$issuer",
           key_id => "$key_ring{$issuer}{key_id}",
       });
    $auth->secret32( encode_base32( $auth->secret() ) );
        printf( "%16s " . semaphore() . " %06d" . RESET ."\n", $issuer, $auth->code() );
    $auth->clear();
}

