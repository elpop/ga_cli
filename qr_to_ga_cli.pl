#!/usr/bin/perl
#===================================================================#
# Program => qr_to_ga_cli.pl (In Perl 5.0)            version 0.0.1 #
#===================================================================#
# Autor         => Fernando "El Pop" Romo        (pop@cofradia.org) #
# Creation date => 01/September/2022                                #
#-------------------------------------------------------------------#
# Info => This program convert a snapshot of the Export accounts of #
#         the Google Authenticator App, Read the QR Code, Decode    #
#         Mime Base64 data, process with protoc (Google Protocol    #
#         Buffers Compiler) and make a conf file to use the program #
#         ga_cli.pl                                                 #
#-------------------------------------------------------------------#
# This code are released under the GPL 3.0 License. Any change must #
# be report to the authors                                          #
#                 (c) 2022 - Fernando Romo                          #
#===================================================================#
use strict;
use Image::Magick;
use Barcode::ZBar;
use MIME::Base64; 
use Google::ProtocolBuffers;
use File::Copy;

# Definition of the Protocol Buffers generated by Google Authenticator Export Accounts options
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
     }",
     {create_accessors => 1}
);

# Work variables
my $qr_data = '';
my %key_ring = ();
my @images = grep {/\.(jpg|jpeg|png)$/} @ARGV; # filter image files from command arguments
my $work_dir = $ENV{'HOME'} . '/.ga_cli'; # key directory

# Process the Protocol Buffers data
sub process_pb_data {
    my $qr_data_ref = shift;
    
    # Check for "otpauth-migration://offline" in the QR info
    if ($$qr_data_ref =~ /^otpauth-migration:\/\/offline/) {
        
        # only take the MIME Data on the QR message
        my ($data) = $$qr_data_ref =~/data=(.*)/;
        
        # URL Decode
        $data =~ s/\%([A-Fa-f0-9]{2})/pack('C', hex($1))/seg;
    
        # Decode Base64 Info
        my $mime_data = decode_base64($data);
      
        # Process Protocol Buffers from de MIME Base64 Data
        my $protocol_buffer = GA->decode("$mime_data");
        foreach my $ref (@{$protocol_buffer->{Index}}) {
            
            # convert the passwords in octal notation
            $ref->{pass} =~ s/[\N{U+0000}-\N{U+FFFF}]/sprintf("\\%03o",ord($&))/eg;
    
            # Assign values to the key ring
            if ($ref->{issuer} ne '') {
                $key_ring{$ref->{issuer}}{secret}    = $ref->{pass};
                $key_ring{$ref->{issuer}}{keyid}     = $ref->{keyid};
                $key_ring{$ref->{issuer}}{algorithm} = $ref->{algorithm};
                $key_ring{$ref->{issuer}}{digits}    = $ref->{digits};
                $key_ring{$ref->{issuer}}{type}      = $ref->{type};
            }
            else {
                $key_ring{$ref->{keyid}}{secret}    = $ref->{pass};
                $key_ring{$ref->{keyid}}{keyid}     = $ref->{keyid};
                $key_ring{$ref->{keyid}}{algorithm} = $ref->{algorithm};
                $key_ring{$ref->{keyid}}{digits}    = $ref->{digits};
                $key_ring{$ref->{keyid}}{type}      = $ref->{type};
            }
        }
    }
    else {
        print "Error: No Google Authenticator Export Data found\n";
    }
}

#-----------#
# Main body #
#-----------#

# create work directory if not exists
unless (-f $work_dir) {
    mkdir($work_dir);
}

# Process if exists the argument with a image filename 
if ($#images >=0) {
    
    # Process images
    foreach my $image (@images) {
        
        # Prepare to Read the QR using ZBar libs
        my $scanner = Barcode::ZBar::ImageScanner->new();
        $scanner->parse_config("enable");
    
        # Use ImageMagick to obtain image properties
        my $magick = Image::Magick->new();
        $magick->Read($image) && die;
        my $raw = $magick->ImageToBlob(magick => 'GRAY', depth => 8);
    
        # Set ZBar reader and read image
        my $image = Barcode::ZBar::Image->new();
        $image->set_format('Y800');
        $image->set_size($magick->Get(qw(columns rows)));
        $image->set_data($raw);
        my $n = $scanner->scan_image($image);
    
        # Read QR Data
        foreach my $symbol ($image->get_symbols()) {
            ($qr_data) = $symbol->get_data();
            # Process the Protocol Buffer Data
            process_pb_data(\$qr_data);
        }
        undef($image);
    }
    
    # if have valid keys, write configuration file
    if ( scalar(keys %key_ring) > 0 ) {
        
        # make a backup (just in case).
        if (-f "$work_dir\/keys") {
            move("$work_dir\/keys", "$work_dir\/keys.back");
        }
        
        # Create and write a conf file called "keys"
        open(CONF, ">:encoding(UTF-8)","$work_dir\/keys") or die "Can't create conf file: $!";
        print CONF "(\n";
        foreach my $issuer (sort { "\U$a" cmp "\U$b" } keys %key_ring) {
            print CONF "    '$issuer' => {\n";
            print CONF "        keyid     => '$key_ring{$issuer}{keyid}',\n";
            print CONF "        secret    => \"$key_ring{$issuer}{secret}\",\n";
            print CONF "        algorithm => $key_ring{$issuer}{algorithm},\n";
            print CONF "        digits    => $key_ring{$issuer}{digits},\n";
            print CONF "        type      => $key_ring{$issuer}{type},\n";
            print CONF "    },\n";
        }
        print CONF ");\n";
        close(CONF);
    }
}
# If you don't give any file, print help
else {
    print "Usage:\n";
    print "    ./qr_to_ga_cli.pl \[image_file(.png|.jpg)\]\n";
}
