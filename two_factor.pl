#!/usr/bin/perl
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

if ($ARGV[0] ne '') {
    my $auth = Auth::GoogleAuth->new({
           secret => 'Another silly passphrase',
           issuer => 'OpenEnchilada',
           key_id => '@El_Pop',
       });
    $auth->secret32( encode_base32( $auth->secret() ) );
    if ($ARGV[0] eq '-qr') {
        my $qrcode = Imager::QRCode->new(
               size          => 4,
               margin        => 1,
               version       => 1,
               level         => 'M',
               casesensitive => 1,
               lightcolor    => Imager::Color->new(255, 255, 255),
               darkcolor     => Imager::Color->new(0, 0, 0),
           );
        my $leyend = 'otpauth://totp/'. $auth->issuer() . ':' . $auth->key_id() . 
                     '?secret=' . $auth->secret32() .'&issuer=' . $auth->issuer();
        $leyend =~ s/\s/\%20/g;
        my $img = $qrcode->plot("$leyend");
        $img->write(file => "two_factor.jpg");
    }
    elsif ($ARGV[0] eq '-info') {
        print 'Passphrase: ' . $auth->secret() . "\n";
        print '   base 32: ' . $auth->secret32() . "\n";
        print '    Issuer: ' . $auth->issuer() . "\n";
        print '    Key_id: ' . $auth->key_id() . "\n";
    }
    elsif ($ARGV[0] eq '-code') {
        printf( "%16s " . semaphore() . " %06d" . RESET ."\n", $auth->issuer(), $auth->code() );
    }
    else {
        if ($auth->verify("$ARGV[0]")) {    
            print "Valid\n";
        }
        else {
            print "Invalid\n";
        }
    }
    $auth->clear();
}
else {
    print "Usage:\n\n";
    print "    1) for Gogle authenticator verification:\n\n";
    print "       ./two_factor.pl \[Code\]\n\n";
    print "    2) To generate qr code for suscribe on Google Authenticator app:\n\n";
    print "       ./two_factor.pl -qr\n\n";
    print "       The file is named 'two_factor.jpg'\n\n"; 
    print "    3) print all info (passphrase, base32, issuer and key_id):\n\n";
    print "       ./two_factor.pl -info\n\n";
    print "    4) print One Time Password like the Google Authenticator app:\n\n";
    print "       ./two_factor.pl -code\n\n";
}
