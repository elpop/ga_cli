# Google Authenticator CLI

## Description

Command Line version of the Google Authenticator App.

Is a set of programs to take the accounts of the Authenticator App, via one snapshot of the Export accounts option, Read de QR Code, Decode the Mime Base64 data, process with protoc (Google Protocol Buffers Compiler) and make a conf file to work with.
    
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

3. Perl Dependencies
    
    [Convert::Base32](https://metacpan.org/pod/Convert::Base32)
    
    [MIME::Base64](https://metacpan.org/pod/MIME::Base64)
    
    [Image::Magick](https://metacpan.org/pod/Image::Magick)
    
    [Imager::QRCode](https://metacpan.org/pod/Imager::QRCode)

    [Barcode::ZBar](https://metacpan.org/pod/Barcode::ZBar)

    [Auth::GoogleAuth](https://metacpan.org/pod/Auth::GoogleAuth)
        
    [Google::ProtocolBuffers](https://metacpan.org/pod/Google::ProtocolBuffers)

    All the Perl Moules are available via [metacpan](https://metacpan.org) or install via de "cpan" program in you system. Debian/Ubuntu and Fedora has packages for the perl modules.
    
## Usage

1. First with use th Google Authenticator App and use The "Export accounts" option, follow the guide and select one or all your accounts, The App has an option to delete the exported accounts, DON'T DELETE YOUR INFO, we use the QR generated like this example:

![](https://github.com/elpop/2fa/blob/main/export_accounts_sample.jpg?raw=true)

2. Transport the image to the Desktop computer and run the key extractor program:

    ```   
    ./qr_to_ga_cli.pl export_accounts_sample.jpg
    ```
    This program generate a file called "ga_cli.conf", is a perl hash definition with the information of your accounts.
    
    The file show the account or accounts info:

    ```
    (
    'OpenEnchilada' => {
        keyid => '@El_Pop',
        secret => "\104\157\156\144\145\040\163\145\040\141\147\165\141\156\164\141\040\166\141\162\141\040\164\145\143\156\157\154\303\263\147\151\143\141" },
    );
    ```
    
3. Use the Google Authenticator CLI Tool

    ```
    ./ga_cli.pl 
        OpenEnchilada  972144
    ```
    
    The ga_cli program shows in color green the values you can use. When only left 5 seconds for Code change, shows the value in color red. The values changes each 30 seconds.
    
    Is important to keep your computer time correct. The TOTP (Time-Based One Time Password) algorithm used in Google Authenticator need a correct time-date. use a NTP (Network Time Protocol) service to do it.
    
## Author

   Fernando Romo (pop@cofradia.org)

## License
     
```
GNU GENERAL PUBLIC LICENSE Version 3
https://www.gnu.org/licenses/gpl-3.0.en.html
See LICENSE.txt
```
