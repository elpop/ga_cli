#!/usr/bin/perl
#===================================================================#
# Program => qr_to_ga_cli.pl (In Perl 5.0)            version 0.0.1 #
#===================================================================#
# Autor         => Fernando "El Pop" Romo        (pop@cofradia.org) #
# Creation date => 01/September/2022                                #
#-------------------------------------------------------------------#
# Info => This program convert a snapshot of the Export accounts of #
#         the Google Authenticator App, Read de QR Code, Decode the #
#         Mime Base64 data, process with protoc (Google Protocol    #
#         Buffers Compiler) and make a conf file to use the program #
#         ga_cli.pl                                                 #
#-------------------------------------------------------------------#
# This code are released under the GPL 3.0 License. Any change must #
# be report to the authors                                          #
#                 (c) 2021 - Fernando Romo                          #
#===================================================================#
use strict;
use Image::Magick;
use Barcode::ZBar;
use MIME::Base64; 
use Google::ProtocolBuffers;

# Definition of the Protocol Buffers generated by Google Authenticator
# Export Accounts options
Google::ProtocolBuffers->parse("
     message OTP {
         message Keys {
                optional string pass   = 1;
                optional string keyid = 2;
                optional string issuer = 3;
         }
	 repeated Keys Index = 1;
     }
     ",
     {create_accessors => 1}
);

# Work variables
my $data = '';
my %key_ring = ();

# Process if exists the argument with a image filename 
if ($ARGV[0] ne '') {
    # Prepare to Read the QR using ZBar libs
    my $scanner = Barcode::ZBar::ImageScanner->new();
    $scanner->parse_config("enable");

    # Use ImageMagick to obtain image properties
    my $magick = Image::Magick->new();
    $magick->Read($ARGV[0]) && die;
    my $raw = $magick->ImageToBlob(magick => 'GRAY', depth => 8);

    # Set Zbar reader and read image
    my $image = Barcode::ZBar::Image->new();
    $image->set_format('Y800');
    $image->set_size($magick->Get(qw(columns rows)));
    $image->set_data($raw);
    my $n = $scanner->scan_image($image);

    # Read QR Data
    foreach my $symbol ($image->get_symbols()) {
        # do something useful with results
        ($data) = $symbol->get_data() =~/data=(.*)/;
    }
    undef($image);

    # URL Encode
    $data =~ s/\%([A-Fa-f0-9]{2})/pack('C', hex($1))/seg;

    # Decode Base64 Info
    my $mime_data = decode_base64($data);

    # Process Protocol Buffers from de MIME Base64 Data
    my $protocol_buffer = OTP->decode("$mime_data");
    foreach my $ref (@{$protocol_buffer->{Index}}) {

    	# convert the passwords in octal notation
	    $ref->{pass} =~ s/[\N{U+0000}-\N{U+FFFF}]/sprintf("\\%03o",ord($&))/eg;

	    # Assign values to the key ring
	    if ($ref->{issuer} ne '') {
            $key_ring{$ref->{issuer}}{secret} = $ref->{pass};
            $key_ring{$ref->{issuer}}{keyid} = $ref->{keyid};
        }
        else {
            $key_ring{$ref->{keyid}}{secret} = $ref->{pass};
            $key_ring{$ref->{keyid}}{keyid} = $ref->{keyid};
        }
    }

    # Create and write a conf file called "ga_cli.conf"
    open(CONF, ">:encoding(UTF-8)","ga_cli.conf") or die "Can't create conf file: $!";
    print CONF "(\n";
    foreach my $issuer (sort keys %key_ring) {
        print CONF "    '$issuer' => {\n";
        print CONF "        keyid => '$key_ring{$issuer}{keyid}',\n";
        print CONF"        secret => \"$key_ring{$issuer}{secret}\" },\n";
    }
    print CONF ");\n";
    close(CONF);
}
# If you don't give any file print help
else {
    print "Usage:\n";
    print "    ./qr_to_ga_cli.pl \[image_file(.png|.jpg)\]\n";
}
