#Enc.pm
#Encryption Module

package Enc;
use strict;
use warnings;
use Crypt::Blowfish;

sub new
{
	my $class = shift;
	my $key = shift; 
	my $self = {key => $key, cipher => Crypt::Blowfish->new($key . ('0'x(32 - length $key)))};
	bless $self, $class;
	return $self;
}

sub encrypt
{
	(my $self, my $file) = @_;
	my $encrypted = '';
	
	open (FILE, '<', $self->{key} . '/' . $file);
	while (read(FILE, my $block, 8)) 
	{
		my $len  = length $block;	
		# Add padding if necessary
		$block .= "\000"x(8-$len) if $len < 8;
		$encrypted .= $self->{cipher}->encrypt($block);
	}
	close(FILE);
	
	open (FILE, '>', $self->{key} . '/' . $file);
	print FILE $encrypted;
	close(FILE);
}

sub decrypt
{
	(my $self, my $file) = @_;
	my $decrypted = '';
	
	open (FILE, '<', $self->{key} . '/' . $file);
	
	while (read(FILE, my $enc, 8)) 
	{
		$decrypted .= $self->{cipher}->decrypt($enc);
	}
	
	close(FILE);
	
	$decrypted =~ s/^\s+//;
	$decrypted =~ s/\s+$//;
	
	open (FILE, '>', $self->{key} . '/' . $file);
	print FILE $decrypted;
	close(FILE);
}

1;