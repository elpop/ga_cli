# Google Authenticator CLI

## Description

Command Line version of the Google Authenticator App.

Program to take the accounts of the Authenticator App, via one snapshot of the Export accounts option, Read de QR Code, Decode the Mime Base64 data, process with protoc (Google Protocol Buffers Compiler) and make a conf file to work with.

## Summary

```
 ./ga_cli.pl -h
Usage:
    ga_cli.pl [options] {file ...}

Options:
    None    Show the TOTP of each account.

                ga_cli.pl

                    OpenEnchilada  972144

    Word    If you pass a value without '-', only shows the ones than
            contain your criteria (case insensitive):

                ga_cli.pl bit

                       BITMAIN  067333
                        BitMEX  376455
                         Bitso  215278

            This is equivalent to:

                ga_cli.pl | grep -i bit

            The following chars could be used on searchs:

                '^' something starting with.
                '$' something ending with.
                '.*' wildcard character.
    
                ga_cli.pl "^p.*m$"
    
                    pool.bitcoin.com  095968

    -list or -l
            The -list or -l option only show the issuer name

                ga_cli.pl -l

            This is equivalent to:

                ga_cli.pl | awk '{print $1}'

    -import or -i
            Import given QR image file:

                ga_cli.pl -import export_accounts_sample.jpg

            The QR image can be the full Google Authenticator Export Set or
            a single account for add to the key ring

            You can process multiple images when Google Authenticator make
            more than one QR:

                ga_cli.pl -v -i qr_one.jpg qr_two.jpg ...

            JPG and PNG formats are supported.

    -export or -e
            Create QR images for export to Googla Authenticator App:

                ga_cli.pl -export

            The program take all the keys on the key ring and create a set
            of files (depending of the keys quantity) named
            "export_keys_YYYYMMDD_XX_of_ZZ.png". where YYYYMMDD is the date,
            XX is the sequence and ZZ the total images on the set.

            Each QR contain 10 keys per image. For example, if you have 25
            keys, we generate 3 QR files:

                export_keys_20220908_01_of_03.png
                export_keys_20220908_02_of_03.png
                export_keys_20220908_03_of_03.png

            Create a QR image for a single account to add to your
            authenticator app:

                ga_cli.pl -e 'your issuer'

            The issuer name must have a exact match to proceed (Case
            sensitive). The image file is named qr_{issuer}.png

            Could use a list of issuers:

                ga_cli.pl -e 'Binance.com' 'Bitso' ...

            You can export all your keys in individual files with a simple
            bash script:

                #!/bin/bash
                issuers=""
                for i in `ga_cli.pl -l`
                do
                   issuers+=" $i" 
                done
                ga_cli.pl -v -e $issuers

    -add or -a
            Add a single account to key ring manually:

                ga_cli.pl -add issuer='your issuer' keyid='me@something.com' secret='A random pass'

    -remove or -r
            Remove a single account from the key ring manually:

                ga_cli.pl -remove issuer='your issuer'

            The issuer name must have a exact match to proceed (Case
            sensitive)

    -clear or -c
            Delete the key ring, works with -import, -add or -export
            options. When use -import or -add, Init the key ring and set new
            values. With -export, generate the QR images and delete the key
            ring.

            Use with caution, you can lose all you keys.

    -verbose or -v
            Show progress when using -import, -export, -add, and -remove
            options

    -help or -h or -?
            Show this help
```
    
## Install

1. Download file
  
    ```
    git clone https://github.com/elpop/2fa.git
    ```  

2. Install library dependecies:

   The programs use the following Libraries and Utilities:
   
    [ZBar Lib](http://zbar.sourceforge.net) for Barcode Reading.
    
    [ImageMagick](https://imagemagick.org) for Image information.
    
    [Protoc (Google Protocol Buffers Compiler)](https://github.com/protocolbuffers/protobuf#protocol-compiler-installation) to process the information conteined in the QR of the Authenticator App.
    
    [Librencode](https://github.com/fukuchi/libqrencode) for QR generation.
    
    Is important to install all the libraries before the perl modules. Debian/Ubuntu and Fedora has packages for all the libraries and utilities.

    for Debian/Ubuntu Linux systems:
    
    ```
    sudo apt-get install zbar-tools imagemagick protobuf-compiler libqrencode-dev
    ```
    
    Fedora/Red-Hat Linux systems:
    
    ```
    sudo dnf install libpng libpng-devel libjpeg libjpeg-devel ImageMagick zbar-devel protobuf qrencode-libs
    ```
    
3. Perl Dependencies
    
    [Convert::Base32](https://metacpan.org/pod/Convert::Base32)
    
    [MIME::Base64](https://metacpan.org/pod/MIME::Base64)
    
    [Image::Magick](https://metacpan.org/pod/Image::Magick)
    
    [Imager::QRCode](https://metacpan.org/pod/Imager::QRCode)

    [Barcode::ZBar](https://metacpan.org/pod/Barcode::ZBar)

    [Auth::GoogleAuth](https://metacpan.org/pod/Auth::GoogleAuth)
        
    [Google::ProtocolBuffers](https://metacpan.org/pod/Google::ProtocolBuffers)

    All the Perl Moules are available via [metacpan](https://metacpan.org) or install via "cpan" program in your system. Debian/Ubuntu and Fedora has packages for the perl modules.
    
    for Debian/Ubuntu Linux systems:
    
    ```
    sudo apt-get install libimage-magick-perl libconvert-base32-perl libimager-qrcode-perl libbarcode-zbar-perl libauth-googleauth-perl libgoogle-protocolbuffers-perl
    ```
    
    Mime::Base64 is available in the Perl core instalation.
    
    Fedora/Red-Hat Linux systems:
    
    ```
    sudo dnf install cpan perl-Convert-Base32 perl-MIME-Base64 ImageMagick-perl perl-Imager
    sudo cpan install Imager::QRCode Barcode::ZBar Auth::GoogleAuth Google::ProtocolBuffers
    ```

4. Put on your search path
    
    Copy the ga_cli.pl program somewhere in your search path:
    
    ```
    cp ga_cli.pl /usr/local/bin/.
    ```

## The two_factor.pl program

Is a tool to generate OTP, validate it and extract general info of a given account. Also can make a QR image to add a new account into the Authenticator App.
    
The options are:
    
```
    ./two_factor.pl 
    Usage:
      
          1) for Gogle authenticator verification:
      
             ./two_factor.pl [Code]
      
          2) To generate qr code for suscribe on Google Authenticator app:
      
             ./two_factor.pl -qr
      
             The file is named 'two_factor.jpg'
      
          3) print all info (passphrase, base32, issuer and key_id):
      
             ./two_factor.pl -info
      
          4) print One Time Password like the Google Authenticator app:
      
             ./two_factor.pl -code
```

You can configure your account data in the body of the program:
    
```
    # Define credentials used by Auth::GoogleAuth  
    my $auth = Auth::GoogleAuth->new({
           secret => 'Another silly passphrase',
           issuer => 'OpenEnchilada',
           key_id => '@El_Pop',
       });
```
    
Only change the secret, issuer and key_id according your preferences.
    
When use the "-qr" option, you see a QR image like the following to add account into the Google Authenticator App:
    
![](https://github.com/elpop/2fa/blob/main/two_factor.jpg?raw=true)

## Author

   Fernando Romo (pop@cofradia.org)

## License
     
```
GNU GENERAL PUBLIC LICENSE Version 3
https://www.gnu.org/licenses/gpl-3.0.en.html
See LICENSE.txt
```
