#!/usr/bin/perl
#=====================================================================#
# Program => ga_cli.pl (In Perl 5.0)                    version 0.0.1 #
#=====================================================================#
# Autor         => Fernando "El Pop" Romo          (pop@cofradia.org) #
# Creation date => 01/September/2022                                  #
#---------------------------------------------------------------------#
# Info => This program is a CLI version of the Google Authenticator   #
#         App. Read the configuration file generated with the program #
#         qr_to_ga_cli.pl and show the OTP from sites                 #
#---------------------------------------------------------------------#
# This code are released under the GPL 3.0 License. Any change must   #
# be report to the authors                                            #
#                     (c) 2022 - Fernando Romo                        #
#=====================================================================#
use strict;
use Auth::GoogleAuth;
use Convert::Base32;

# Text Colors
use constant {
    RESET    => "\033[0m",
    FG_RED   => "\033[31m",
    FG_GREEN => "\033[32m",
};

my $work_dir = $ENV{'HOME'} . '/.ga_cli'; # key directory

my %key_ring = ();

# Load config File
if (-f "$work_dir\/keys") {
    %key_ring = do "$work_dir\/keys";
}

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

# if have valid keys, process
if ( scalar(keys %key_ring) > 0 ) {

    # Generate OTP
    foreach my $issuer (sort { "\U$a" cmp "\U$b" } keys %key_ring) {
        my $auth = Auth::GoogleAuth->new({
               secret => "$key_ring{$issuer}{secret}",
               issuer => "$issuer",
               key_id => "$key_ring{$issuer}{key_id}",
           });
        $auth->secret32( encode_base32( $auth->secret() ) );
        my $out = sprintf( "%30s " . semaphore() . " %06d" . RESET ."\n", $issuer, $auth->code() );
        
        # Filter output 
        if ($ARGV[0] ne '' ) {
            if ($issuer =~ /$ARGV[0]/i) {
               print $out;
            }
        }
        else {
            print $out;
        }
        $auth->clear();
    }
}
else {
    print "Error: No keys found\n";
}
