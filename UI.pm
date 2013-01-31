#UI.pm
#UI Module

package UI;
use strict;
use warnings;
use Tk;
use Tk::TextUndo;
use Tk::Dialog;
use Tk::DialogBox;
use Tk::LabEntry;
use Tk::Pane;
use Users;
use Enc;

our $VERSION = "1.0";

#UI constructor
sub new
{
	my $class = shift;
	
	my $self = {mw => 0 , text => 0, frame_files => 0, dir => 0, current_file => '', buttons => {}, enc => 0};
	
	bless $self, $class;
	return $self;
}

# Handles a login request dies an error if wrong login

sub login
{
	(my $self, my $user, my $pass) = @_;
	
	my $users = Users->new;

	die "Incorrect Login.\n" if ($self->{dir} = $users->login($user, $pass)) eq 0;
}

# Initialisation of the UI 
# - Creation of main window
# - Adding File manager (side menu)
# - Adding the text field

sub init
{
	my $self = shift;
	
	#Creating the main window
	$self->{mw} = new MainWindow;
	$self->{mw}->title("Electronic Diary");
	
	#Loading the encryption class
	$self->{enc} = Enc->new($self->{dir});
	
	#Adding the file manager
	$self->{frame_files} = $self->{mw}->Scrolled('Frame',-scrollbars=>'osoe',-height => 500, -width => 200);
	
	mkdir $self->{dir} if(not -d $self->{dir});
	opendir(DIR, $self->{dir}) || die("Cannot open directory");
	 
	my @files= readdir(DIR);
	foreach my $f (@files)
	{
		#adding button for each file + adding a ref to the self->buttons array in order to destroy it later;
		$self->{buttons}{$f} = $self->{frame_files}->Button(-text => $f,
														  	-height => 2,
														  	-width => 25,
														  	-command => [\&getafile, $self, $f])->pack(-side => 'top',
														 					 						   -fill => 'x') unless $f eq '.' or $f eq '..';
	}
	closedir(DIR);

	#packing the frame with the menu buttons
	$self->{frame_files}->pack(-side => 'left', -expand => 0);
	
	#Creating the text area
	$self->{text} = $self->{mw}->Scrolled('TextUndo',
										   -scrollbars=>'osoe',
										   -height => 40)->pack(-side => 'right', 
										   						-expand => 1, 
										   						-fill => 'both');
	
	#Creating a handler to save the file on window close
	$self->{mw}->protocol(WM_DELETE_WINDOW => [\&save_and_close, $self]);
}

# Creation of the main menu
sub main_menu
{
    my $self = shift;
	my $menu = $self->{mw}->menu();
	$menu->delete(0, 1);
	
	$self->{mw} -> configure(-menu => $menu);
	
	my $view = $menu->menu();  
	$view->delete(0, 1);
	       
	$menu->cascade(
	              -label => "View",
	              -underline => 0,
	              -menu => $view
	          );
	                    
	$menu->command(
	              -label => "New",
	              -underline => 0,
	              -command => [\&newFile, $self]
	          );
	
	$menu->command(
	              -label => "Save",
	              -underline => 0,
	              -command => [\&save, $self]
	          );
	
	$menu->command(
	              -label => "Delete",
	              -underline => 0,
	              -command => [\&delete, $self]
	          );
	
	$view->command(
					-label => "Order by Title",
	                -underline => 0,
	                -command => [\&ord_by,'t']
			  );
			  
	$view->command(
					-label => "Order by Date",
	                -underline => 0,
	                -command => [\&ord_by,'n']
			  );
}

#Main Loop
sub main_loop
{
	MainLoop;
}

#--------------------------------------------------------------------
#Helper functions for the UI

#Creates a new file, selects it for editing and adds it to the side menu
sub newFile
{
	my $self = shift;
	my $file, my $answer;
	
	my $db = $self->{mw}->DialogBox(-title => 'New File', 
									-buttons => ['Create', 'Cancel'], 
                     				-default_button => 'Create');
                     
	$db->add('LabEntry',
			 -textvariable => \$file, 
			 -width => 40, 
	         -label => 'File Name', 
	         -labelPack => [-side => 'left'])->pack;
	         
	$answer = $db->Show();
	
	if ($answer eq "Create") 
	{
		my $full_path = $self->{dir}.'/'.$file;
		
		open FILE, '>' ,$full_path;
		close FILE;
		
		$self->{text}->Load($full_path);
		$self->{current_file} = $file;
		$self->{mw}->title("Electronic Diary - ".$file);
		
		$self->{frame_files}->Button(-text => $file,
									 -height => 2,
									 -command => [\&getafile, $self, $file])->pack(-side => 'top',
									 					 						-fill => 'x')
	}
}

#Gets a file and selects it for editing
sub getafile
{
	(my $self, my $file) = @_;
	
	if(not $file eq $self->{current_file})
	{
		save($self, $self->{current_file}) if(not $self->{current_file} eq '');
		$self->{enc}->decrypt($file);
	
		$self->{text}->Load($self->{dir}.'/'.$file);	
		$self->{current_file} = $file;
		$self->{mw}->title("Electronic Diary - ".$file);
	}
} 

#Saves a file
sub save
{
	my $self = shift;
	
	if(not $self->{current_file} eq '')
	{
		 $self->{text}->Save();
		 $self->{enc}->encrypt($self->{current_file});
	}
	else
	{
		my $db = $self->{mw}->Dialog(-title => 'Error', 
									 -text => 'Please select a file first.',
									 -buttons => ['Ok'], 
                     				 -default_button => 'Ok')->Show();
	}
}

#Saves the current file and exits
sub save_and_close
{
	my $self = shift;
	save $self;
	$self->{mw}->destroy;
}

#Deletes a file
sub delete
{
	my $self = shift;
	if($self->{current_file})
	{
			my $db = $self->{mw}->Dialog(-title => 'Deleting a file', 
									 -text => 'Are you sure ?',
									 -buttons => ['Yes', 'Cancel'], 
                     				 -default_button => 'Yes')->Show();
            if($db eq 'Yes')
            {
            	$self->{text}->EmptyDocument();
				$self->{mw}->title("Electronic Diary");
				unlink($self->{dir}.'/'.$self->{current_file});
				$self->{buttons}{$self->{current_file}}->destroy;
            }        				 
	}
	else
	{
		my $db = $self->{mw}->Dialog(-title => 'Error', 
									 -text => 'Please select a file first.',
									 -buttons => ['Ok'], 
                     				 -default_button => 'Ok')->Show();
	}
}

sub ord_by
{
	print @_;	
}

1;