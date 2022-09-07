#!/usr/bin/perl
#===================================================================#
# Program => ga_cli_to_qr.pl (In Perl 5.0)            version 0.0.1 #
#===================================================================#
# Autor         => Fernando "El Pop" Romo        (pop@cofradia.org) #
# Creation date => 06/September/2022                                #
#-------------------------------------------------------------------#
# Info => This program Read the /etc/ga_cli.conf file and generate  #
#         QR images for Bulk load into the Google Authenticator App.#
#-------------------------------------------------------------------#
# This code are released under the GPL 3.0 License. Any change must #
# be report to the authors                                          #
#                 (c) 2022 - Fernando Romo                          #
#===================================================================#
use strict;
use MIME::Base64; 
use Google::ProtocolBuffers;
use Imager::QRCode;

# Definition of the Protocol Buffers generated by Google Authenticator
# Export Accounts options
Google::ProtocolBuffers->parse("
    syntax = \"proto2\";
    message GA {
        repeated Keys Index = 1;
        message Keys {
            required string    pass      = 1;
            required string    keyid     = 2;
            optional string    issuer    = 3;
            optional Algorithm algorithm = 4;
            optional DigitSize digits    = 5;
            optional OtpType   type      = 6;
            optional int64     counter   = 7;
            enum Algorithm  {
                ALGO_UNSPECIFIED = 0;
                SHA1             = 1;
                SHA256           = 2;
                SHA512           = 3;
                MD5              = 4;
            }
            enum DigitSize {
                DS_UNSPECIFIED = 0;
                SIX            = 1;
                EIGHT          = 2;
            }
            enum OtpType {
                OT_UNSPECIFIED = 0;
                HOTP           = 1;
                TOTP           = 2;
            }
         }
         optional int32 version = 2;
         optional int32 QRCount = 3;
         optional int32 QRIndex = 4;
         optional int32 batch   = 5;
     }",
     {create_accessors => 1}
);

# Work variables
my $work_dir = $ENV{'HOME'} . '/.ga_cli'; # key directory

# Load config File
my %key_ring = do "$work_dir\/keys";

my %bulk_ring = ( 'version' => 1,
                  'QRCount' => 1,
                  'QRIndex' => 0, );
my $ga_qr = 'otpauth-migration://offline?data=';    

my $count = scalar(keys(%key_ring));
my $images_count = int($count / 10);
if ( ($count % 10) > 0) {
    $images_count++;
}
$bulk_ring{QRCount} = $images_count;
my $seq = 0;
my $current = 1;

# Load Protocol Buffer Array to process
foreach my $issuer (sort { "\U$a" cmp "\U$b" } keys %key_ring) {
    $seq++;
    push @{$bulk_ring{'Index'}},
         ({
          'issuer'    => "$issuer",
          'keyid'     => "$key_ring{$issuer}{keyid}",
          'pass'      => "$key_ring{$issuer}{secret}",
          'algorithm' => $key_ring{$issuer}{algorithm},
          'digits'    => $key_ring{$issuer}{digits},
          'type'      => $key_ring{$issuer}{type},
         });
    if ( ( ($seq % 10) == 0 )
        || ($seq == $count) ) {
        # Process Protocol Buffers from de MIME Base64 Data
        my $protocol_buffer = GA->encode(\%bulk_ring);

        # Encode MIME Base64                
        my $mime_data = encode_base64($protocol_buffer);

        # URL Encode
        $mime_data =~ s/([^A-Za-z0-9])/sprintf("%%%02X", ord($1))/seg;

         # generate QR image
         my $qrcode = Imager::QRCode->new(
                size          => 4,
                margin        => 1,
                version       => 1,
                level         => 'M',
                casesensitive => 1,
                lightcolor    => Imager::Color->new(255, 255, 255),
                darkcolor     => Imager::Color->new(0, 0, 0),
         );
         my $img = $qrcode->plot("$ga_qr$mime_data");
         my $qr_file = 'bulk_keys_' . sprintf("%02d",$current) . '_of_' . sprintf("%02d", $images_count) . '.jpg';
         $img->write(file => "$qr_file");
         $bulk_ring{'Index'} = ();
         $bulk_ring{QRIndex} = $current++;
    }
}