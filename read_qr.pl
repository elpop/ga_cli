#!/usr/bin/perl
#=====================================================================#
# Program => read_qr.pl (In Perl 5.0)                   version 1.0.0 #
#=====================================================================#
# Autor         => Fernando "El Pop" Romo          (pop@cofradia.org) #
# Creation date => 28/march/2025                                      #
#---------------------------------------------------------------------#
# Info => This program read an print the content of a QR Image.       #
#---------------------------------------------------------------------#
# This code are released under the GPL 3.0 License. Any change must   #
# be report to the authors                                            #
#                     (c) 2025 - Fernando Romo                        #
#=====================================================================#
use strict;
use Barcode::ZBar; # Read QR code
use Image::Magick; # Handle image info

#------------------#
# Read the QR data #
#------------------#
sub read_image {
    
    my $images_ref = shift;
    
    my $qr_data = '';
    my @images = grep {/\.(jpg|jpeg|png)$/} @{$images_ref}; # filter image files from command arguments
            
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
            if ($n > 0) {            
                foreach my $symbol ($image->get_symbols()) {
                    ($qr_data) = $symbol->get_data();
                    # Print the content of the QR Code
                    print "$qr_data\n";
                }
            }
            else {
                print "no QR image found\n";
            }
            undef($image);
        }
    }
    # If you don't give any file, print help
    else {
        print "Only work with jpeg or png files\n";    
    }    
} # End sub import_qr()

#-----------#
# Main body #
#-----------#

if ($#ARGV >= 0) {
    read_image(\@ARGV);
}
else {
    print "Usage:\n";
    print "    ./read_qr.pl \[image_file(.png|.jpg)\]\n";    
}
# End Main Body #
