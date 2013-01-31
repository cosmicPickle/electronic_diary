#!/usr/bin/perl
use strict;
use warnings;
use UI;
use Users;

#New User
my $func = shift;

if($func eq '-nu')
{
	die "To create a new user you need to provide a username and a password.\n" if(!defined($ARGV[0]) or !defined($ARGV[1]));
	
	Users->new->create(@ARGV);
}

#Delete User
if($func eq '-du')
{
	die "To delete a user you need to provide a username and a password.\n" if(!defined($ARGV[0]) or !defined($ARGV[1]));
	
	Users->new->delete_user(@ARGV);
}

#Main application (Start)
if($func eq '-s')
{
	die "Incorrect Login.\n" unless defined($ARGV[0]) and defined($ARGV[1]);
	
	#Loading the UI
	my $ui = UI->new;
	$ui->login(@ARGV);
	$ui->init;
	$ui->main_menu;
	$ui->main_loop;
}

