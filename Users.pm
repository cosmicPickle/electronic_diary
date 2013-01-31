#Users.pm
#Users Module

package Users;
use strict;
use warnings;
use Digest::MD5 qw(md5 md5_hex md5_base64);
use File::Path;

our $VERSION = "1.0";

sub new
{
	my $class = shift;
	my $self = {};
	bless $self, $class;
	return $self;
}

sub login
{
	(my $self, my $user,my $pass) = @_;
	$pass = md5_hex($pass);
	open (PASSWD,"<.passwd");
	while(my $line = <PASSWD>)
	{
		if(not $line eq "\n")
		{
			(my $cuser, my $cpass) = split ' ', $line;
			return md5_hex($user) if $user eq $cuser and $pass eq $cpass;
		}
	}
	close(PASSWD);
	return 0;
}

sub create
{
	(my $self,my $user,my $pass) = @_;
	$pass = md5_hex($pass);
	open (PASSWD,">>.passwd");
	print PASSWD "\n".$user.' '.$pass;
	print "User successfully created";
}

sub delete_user
{
	(my $self, my $user,my $pass) = @_;
	$pass = md5_hex($pass);
	open (PASSWD,"<.passwd");
	my $new_passwd = '';
	my $not_found = 1;
	while(my $line = <PASSWD>)
	{
		if(not $line eq "\n")
		{
			(my $cuser, my $cpass) = split ' ', $line;
			$new_passwd .= $line if(not $user eq $cuser or not $pass eq $cpass);
			$not_found = 0 if $user eq $cuser and $pass eq $cpass;
		}
	}
	
	close(PASSWD);
	
	open (PASSWD,">.passwd");
	print PASSWD $new_passwd;
	
	if($not_found == 0)
	{
		rmtree md5_hex($user);
		rmdir md5_hex($user);
	}
	
	print "User successfully deleted" if($not_found == 0);
	print "User not found" if($not_found == 1);
}
1;