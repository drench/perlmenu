# vim: se ts=2 expandtab :
#****************************************************************************
# perlmenu.pm -- Perl Menu Support Facility 
#
# Version: 4.0
#
# Author:  Steven L. Kunz
#          Networked Applications
#          Iowa State University Computation Center
#          Ames, IA  50011
#
# Major Contributors (Version 3.0, 3.1):
#          Chris Candreva (chris@westnet.com)
#          WestNet Internet Services of Westchester
#
#          Alan Cunningham
#          NASA Spacelink Project
#
# Official PerlMenu WWW home page:
#	   http://www.cc.iastate.edu/perlmenu/
#
# Official Package Distributions:
#          ftp://ftp.iastate.edu/pub/perl
#
# Bugs:    skunz@iastate.edu
# Cheers:  skunz@iastate.edu
#
# Date:    Version 1.0 -- May, 1992 -- Original version 
#          Version 1.1 -- Aug, 1992 -- Minor enhancements, bugfixes
#          Version 1.2 -- Nov, 1992 -- Selection bugfix
#          Version 1.3 -- Dec, 1992 -- "top" and "latch" functions added
#          Version 1.4 -- Apr, 1993 -- "r=refresh" added to bottom line
#          Version 2.0 -- Sep, 1993 -- Radio-button, Multiple-selection,
# 				       shell-escape, new "hot-keys", and
#				       "menu_getstr" routine.
#          Version 2.1 -- Oct, 1993 -- Bug fixes
#          Version 2.2 -- Mar, 1994 -- Menu sub-titles
#          Version 2.3 -- Jun, 1994 -- Bug fixes
#          Version 3.0 -- Jan, 1995 -- Templates, lots of new options on
#                                      many calls, Perl5 interfacing.
#          Version 3.1 -- Mar, 1995 -- Bug fixes, new "menu_template_setexit"
#                                      call, new menu_pref.
#          Version 3.2 -- Jun, 1995 -- Bug fixes, template "required field"
#                                      support, template Control-L refresh.
#          Version 3.3 -- Feb, 1996 -- Bug fixes, help routines, templates
#                                      from arrays ("menu_load_template_array")
#          Version 4.0 -- Feb, 1997 -- Converted to "pm" module, highlighted
#				       selection cursor pref, Multiple-column
#				       menus pref, bug fixes
#
# Notes:   Perl4 - Requires "curseperl"
#                  (distributed with perl 4.36 in the usub directory)
#          Perl5 - Requires "Curses" extension available from any CPAN
#		   site (http://www.perl.com/CPAN/CPAN.html).
#                  
#                  Put the following at top of your code:
#
#                    BEGIN { $Curses::OldCurses = 1; }
#                    use Curses;
#
#          Use:
#             &menu_init(1,"title");
#             &menu_item("Topic 1","got_1");
#             &menu_item("Topic 2","got_2");
#             ...
#             &menu_item("Topic n","got_n");
#             $sel_text = &menu_display("Select using arrow keys");
#
# PerlMenu - Perl library module for curses-based menus & data-entry templates
# Copyright (C) 1992-97  Iowa State University Computation Center
#                        Ames, Iowa  (USA)
#
#    This Perl library module is free software; you can redistribute it
#    and/or modify it under the terms of the GNU Library General Public
#    License (as published by the Free Software Foundation) or the
#    Artistic License.
#
#    This library is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of 
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#    Library General Public License for more details.
#
#    You should have received a copy of the GNU Library General Public
#    License along with this library; if not, write to the Free
#    Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#
#****************************************************************************

package perlmenu;

#%PERL5ONLY% DO NOT REMOVE OR CHANGE THIS LINE
BEGIN { $Curses::OldCurses = 1; }
use Curses;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(
  menu_curses_application menu_prefs menu_template_prefs menu_shell_command
  menu_quit_routine menu_init menu_paint_file menu_setexit menu_getexit
  menu_item menu_display menu_display_radio menu_display_mult menu_getstr
  menu_template_setexit menu_load_template menu_load_template_array
  menu_overlay_clear menu_overlay_template menu_display_template 
  );
#%PERL5ONLY% DO NOT REMOVE OR CHANGE THIS LINE

# PERL5 ONLY (GETCAP PROBLEMS)
# Uncomment these statements if you DON'T have "getcap()" OR
# if the demo doesn't appear to work (there's a bug in some getcap's).
#

package Perl5::Menu_PL::Compat;	# Don't pollute perlmenu.pm namespace
require Term::Cap;			# Get Tgetent package
my $term = Tgetent Term::Cap { OSPEED => 9600 };	   # Define entry
sub perlmenu::getcap { $term->{"_" . shift()} };  # Define local subroutine

package perlmenu;

# PERL4 ONLY (GETCAP PROBLEMS)
# Uncomment these statements if you DON'T have "getcap()" OR
# if the demo doesn't appear to work (there's a bug in some getcap's).
#
#if (($] >= 4.0) && ($] < 5.0)) {	# Perl4 ONLY!
#package simgetcap;			# Don't pollute menu.pl namespace
#$ispeed = $ospeed = 13;		# Set old-style "9600";
#require "termcap.pl";			# Get Tgetent package
#&Tgetent($ENV{'TERM'});		# Load $TC array
#sub main'simgetcap { $TC{shift}; };	# Define local subroutine
#}

# Preferences (set by "menu_pref")
$curses_application = 0;	# Application will do initscr, endwin
$center_menus = 0;		# Center menus
$gopher_like = 0;		# More gopher-like arrow keys
$disable_quit = 0;		# Disable "Quit" hot-key
$quit_prompt = "";		# Override Quit prompt
$quit_default = "y";		# Quit default response
$multiple_column = 0;		# Multiple column menus
$highlight = 0;			# Highlight selection points

$menu_exit_routine = "main'clear";
$menu_generic_help_routine = "menu_default_show_help";
$menu_item_help_routine = "";
$menu_shell_text = "";
$menu_is_first_one = 1;
$menu_is_top_one = 0;
$menu_top_activated = 0;
$finding_top = 0;
@menu_sel_text = ();	# Menu item selection text
@menu_sel_action = ();	# Menu item actions
@selected_action = ();	# Menu item selected flags (multiple-selection menus)
@menu_sub_title = ();	# Top Sub-title strings
$menu_sub_titler = "";	# Top Sub-title builder routine
@menu_bot_title = ();	# Bottom title strings
$menu_bot_titler = "";	# Bottom title builder routine
$did_initterm = 0;	# We already got escape sequences for arrows, etc.
$window = 0;		# Base window
$xrow = $xcol = 0;
$first_line = $last_line = $item_lines_per_screen = 0;
$items_per_screen = $items_per_line = 0;
$arrow_col = $arrow_line = 0;
$max_sel_line = $max_sel_col = 0;
$menu_top_item = 0;
$arrow_spec_row = $arrow_spec_col = 0;
 
@menu_exitkeys = ();	# Exit-key strings
$menu_lastexit = "";	# Exit-key string that caused the last exit
$show_mail = "";
$max_item_len = 0;	# Length of longest selection text
$left_margin = 0;	# Leftmost column of menu (for centering)
$prepend_len = 0;	# Length of text we prepend to each selection
$column_width = 0;	# Width of each item in column

$ku = $ansi_ku = $kd = $ansi_kd = "";
$field = 0;			# Count of loaded template fields
$template_exit_active = 0;	# Currently processing a template user exit
@template_exitkeys = ();	# Exit-key strings
@menu_template_line = ();	# Template text line
@menu_template_row = ();	# Data entry rows
@menu_template_col = ();	# Data entry cols
@menu_template_len = ();	# Data entry lengths
@menu_template_type = ();	# Data entry type
				# (0=alpha-numeric, 1=numeric, 2=no-show)

$last_window_cpos = 0;		# Storage to last windows cursor position.

@menu_overlay_row = ();		# Template overlay row
@menu_overlay_col = ();		# Template overlay col
@menu_overlay_text = ();	# Template overlay text
@menu_overlay_rend = ();	# Template overlay rendition
@menu_overlay_stick = ();	# Template overlay "sticky" flags

$req_lmark_set = "*";		# Marker for required fields - left (set)
$req_lmark_clear = " ";		# Marker for required fields - left (clear)
$req_lmark_attr = 0;		# Marker attribute - left (0=normal,1=standout)
$req_rmark_set = "";		# Marker for required fields - right (set)
$req_rmark_clear = "";		# Marker for required fields - right (clear)
$req_rmark_attr = 0;		# Marker attribute - right (0=normal,1=standout)
@req_mark_row = ();		# Required field markers - rows
@req_lmark_col = ();		# Required field markers - left cols
@req_rmark_col = ();		# Required field markers - right cols

# Simple emacs-style editing key definitions
$begin_of_line  = "\cA";
$end_of_line    = "\cE";
$next_char      = "\cF";
$prev_char      = "\cB";
$next_field     = "\cN";
$prev_field     = "\cP";
$redraw_screen  = "\cL";
$delete_right   = "\cD";
$kill_line      = "\cK";
# Normally yank_line would be "\cY" (C-y), unfortunately both C-z and C-y are
# are used to send the suspend signal in our environment. Bind it to
# C-u for a lack of anything better.
$yank_line      = "\cU"; 
# buffer
$kill_buffer    = "";

#**********
#  MENU_CURSES_APPLICATION
#
#  Function:	Indicate application is using curses calls.  If called, 
#		the menu routines will not do initscr and endwin calls 
#		(the application must do them).
#
#  Call format:	&menu_curses_application(window);
#
#  Arguments:	The main window (gotten from an initscr call)
#
#  Returns:	Main window (either passed in or gotten here)
#**********
sub menu_curses_application {
  ($window) = @_;
  $curses_application = 1;

# Sanity check.  If no window, get one.
  if (!$window) { $window = &initscr(); start_color(); }

  $window;
}

#**********
#  MENU_PREFS
#
#  Function:	Establish general default preferences for menu style.
#
#  Call format:	&menu_pref(center_menus,gopher_like,quit_flag,quit_prompt,
#			   quit_def_resp,mult_col_menu,highlight_sel_text);
#
#  Arguments:	- Boolean flag (0=left justified menus, 1=centered menus)
#		- Boolean flag (0=normal, 1=more gopher-like)
#		- Boolean flag (0=allow quit, 1=disable quit)
#		- String with default "Quit" prompt
#		- String with "Quit" default response character
#		- Boolean flag (0=single column menus, 1=multiple column menus
#		- Boolean flag (0=arrow in front of selection text,
#				1=highlight selection text (no arrow)
#
#  Returns:	Nothing
#**********
sub menu_prefs {
  ($center_menus,$gopher_like,$disable_quit,$quit_prompt,$quit_default,
   $multiple_column,$highlight) = @_;

# Don't allow bad default characters.
  if (($quit_default ne "Y") && ($quit_default ne "y") &&
      ($quit_default ne "N") && ($quit_default ne "n")) {
    $quit_default = "y";
  }
}

#**********
#  MENU_TEMPLATE_PREFS
#
#  Function:	Establish general default preferences for templates.
#
#  Call format:	&menu_template_pref(mark-set-left,mark-clear-left,left-attr,
#				   mark-set-right,mark-clear-right,right-attr);
#
#  Arguments:	- Required field marker flag string (for left of field)
#		- Required field marker flag clear string (for left of field)
#		- Attribute for left marker (0=normal,1=standout)
#		- Required field marker flag string (for right of field)
#		- Required field marker flag clear string (for right of field)
#		- Attribute for right marker (0=normal,1=standout)
#
#  Returns:	Nothing
#**********
sub menu_template_prefs {
  ($req_lmark_set,$req_lmark_clear,$req_lmark_attr,
   $req_rmark_set,$req_rmark_clear,$req_rmark_attr) = @_;
}

#**********
#  MENU_SHELL_COMMAND
#
#  Function:	Enable "!" as shell escape from a menu and indicate the 
#		command that should be issued.
#
#  Call format:	&menu_shell_command("shell-path command");
#
#  Arguments:	Shell path (such as "/bin/csh") to start shell spawn-off.
#		If null value is supplied, shell escape is disabled.
#
#  Returns:	Nothing
#**********
sub menu_shell_command { ($menu_shell_text) = @_; }

#**********
#  MENU_QUIT_ROUTINE
#
#  Function:	Specify a "cleanup" routine to be called before a "quit"
#		from the application is processed.
#
#  Call format:	&menu_quit_routine("string");
#
#  Arguments:	String containing name of exit routine to call.
#
#  Returns:	Nothing.
#
#**********
sub menu_quit_routine { $menu_exit_routine = "main'@_"; }

#**********
#  MENU_HELP_ROUTINE
#
#  Function:	Specify a "help" routine to be called when "h" or "H"
#		is pressed during menu display.
#
#  Call format:	&menu_help_routine("string");
#
#  Arguments:	String containing name of help routine to call.
#               If a null string is provided, the default routine is used.
#
#  Returns:	Nothing.
#
#**********
sub menu_help_routine {
  local($rtn) = @_;  
  if ($rtn eq "") {
    $menu_generic_help_routine = "menu_default_show_help";
  } else {
    $menu_generic_help_routine = "main'$rtn";
  }
}

#**********
#  MENU_INIT
#
#  Function:	Initialize menu type (numbered or unnumbered), arrays, 
#		title, and "top" flags.
#
#  Call format:	&menu_init([0|1],"Top Title",[0|1],"Sub Titles");
#
#  Arguments:   Boolean flag indicating whether or not a arrows and numbers
#               are desired (0=no, 1=yes) and title text (for the top line
#               of menu), an optional boolean top-menu indicator, and an
#               optional sub-title.
#
#  Returns:	Window value from "initscr" call.
#
#  Notes:	1) If the title string begins with a "-" the title is not
#		   presented in reverse-video ("standout") representation.
#		2) Optional sub-titles have two controls characters (which
#		   are order dependant.  A "-" functions as in the title.
#		   A "<" or ">" as the next character (or first, if "-"
#		   is not used) performs left or right justification.
#		3) If this is the FIRST menu_init call and the optional
#		   third opernd is "1", it is the "top" menu.
#**********
sub menu_init {
  ($menu_numbered,$menu_top_title,$menu_is_top_one,$sub_titles,$bot_titles,
   $item_help) = @_;
  local($i,$justify);

# Perform initscr if not a curses application
  if (!$curses_application && !$window) { $window = &initscr(); }

# Load "magic sequence" array based on terminal type
  if (!$did_initterm) {		# Get terminal info (if we don't have it).
    &defbell() unless defined &bell;

# Method 1 (getcap)
# Uncomment if you have "getcap"
    $ku = &getcap('ku');	# Cursor-up
    $kd = &getcap('kd');	# Cursor-down
    $kr = &getcap('kr');	# Cursor-right
    $kl = &getcap('kl');	# Cursor-left
    $cr = &getcap('cr');	# Carriage-return
    $nl = &getcap('nl');	# New-line

# Method 2 (tigetstr)
# Uncomment if you have tigetstr (Solaris) instead of "getcap"
#    $ku = &tigetstr('kcuu1');	# Cursor-up
#    $kd = &tigetstr('dcud1');	# Cursor-down
#    $kr = &tigetstr('kcuf1');	# Cursor-right
#    $kl = &tigetstr('kcub1');	# Cursor-left 
#    $cr = &tigetstr('cr');	# Carriage-return
#    $nl = &tigetstr('nl');	# New-line

# Method 3 (tput)
# Uncomment if you have terminfo (and tput) instead of "getcap"
#    $ku = `tput kcuu1`;	# Cursor-up
#    $kd = `tput kcud1`;	# Cursor-down
#    $kr = `tput kcuf1`;	# Cursor-right
#    $kl = `tput kcub1`;	# Cursor-left
#    $cr = `tput kent`;		# Carriage-return
#				# HP-UX 9.05 users: try $cr = `tput cr` if
#				#                   "tput kent" gives errors
#    $nl = `tput nel`;		# New-line

    $ansi_ku = "\033[A";	# Ansi cursor-up (for DEC xterm)
    $ansi_kd = "\033[B";	# Ansi cursor-down (for DEC xterm)
    $ansi_kr = "\033[C";	# Ansi cursor-right (for DEC xterm)
    $ansi_kl = "\033[D";	# Ansi cursor-left (for DEC xterm)

    @magic_seq = ($ku,$ansi_ku,$kd,$ansi_kd,$kl,$ansi_kl,$kr,$ansi_kr,
		  $cr,$nl,"\n",
		  "n","N"," ","p","P","b","B","e","E",
		  $begin_of_line, $end_of_line, 
		  $next_char, $prev_char,
		  $next_field, $prev_field,
		  $redraw_screen,
		  $delete_right,
		  $kill_line, $yank_line,
		  "a","A","c","C","m","M","=","/","h","H","?","!");
    $did_initterm = 1;
  }

# Check for title format character.
  $menu_top_title_attr = 0;
  if (substr($menu_top_title,0,1) eq '-') {
    $menu_top_title = substr($menu_top_title,1);
    $menu_top_title_attr = 1;
  }

# Center top title
  if (length($menu_top_title) >= $main'COLS) {
    $menu_top_title = substr($menu_top_title,0,$main'COLS-1);
    $menu_top_title_col = 0;
  }
  else {
    $menu_top_title_col = int($main'COLS/2) - int(length($menu_top_title)/2);
  }

# Process any sub-titles like the title.
  @menu_sub_title = (); $menu_sub_titler = "";
  @menu_bot_title = (); $menu_bot_titler = "";

  $first_line = 2;		# Assume no sub-titles for now
  $last_line = $main'LINES - 3;	# Assume no bottom-titles for now
  if ($sub_titles ne "") {
    if ($sub_titles =~ /^&/) {
      $menu_sub_titler = "main'".substr($sub_titles,1);	# Run-time routine
    } else {
      $first_line += &proc_titles($sub_titles,*menu_sub_title,
				*menu_sub_title_attr,*menu_sub_title_col);
    }
  }
  if ($bot_titles ne "") {
    if ($bot_titles =~ /^&/) {
      $menu_bot_titler = "main'".substr($bot_titles,1);	# Run-time routine
    } else {
      $last_line  -= &proc_titles($bot_titles,*menu_bot_title,
				*menu_bot_title_attr,*menu_bot_title_col);
      $last_line--;		# Blank line between menu and bottom titles
    }
  }
  $item_lines_per_screen = $last_line - $first_line + 1;
  $arrow_line = $first_line;    # Arrow on top item by default
  $arrow_col = 0;		# Arrow on leftmost item by default

# Process item help routine.
  $menu_item_help_routine = "";
  if ($item_help) { $menu_item_help_routine = "main'$item_help"; }
  
# Enable "top menu" functions if first menu is a top menu.
  if ($menu_is_first_one && $menu_is_top_one) { $menu_top_activated = 1; }
  $menu_is_first_one = 0;

# Init selection array
  @menu_sel_text = ();		# Selection text for each item
  @menu_sel_action = ();	# Action text for each item
  @selected_action = ();	# Selected items (multiple selection menus)
  $menu_index = 0;		# Reset flags

# Init some other key variables
  $menu_top_item = 0;		# First item is the top item by default
  $last_menu_top_item = -1;	# Force drawing of menu items
  $max_item_len = 0;		# Reset max length

# Return window value from "initscr" call.
  $window;
}

#***********
#  MENU_PAINT_FILE
#
#  Function: Define a text file to display with a menu
#
#  Call format: &menu_paint_file("name_of_file",top_bottom_flag);
#
#  Arguemnts:	- File name to display
#		- Location (0=sub-title area, 1=bottom-title area
#
#  Returns:	0=Success, 1=Cannot open file
#***********
sub menu_paint_file {
  ($paint_file,$top_bot) = @_;
  local($concat_string,$i);

  open(INFILE,$paint_file) || return(1);

# Reset appropriate array and first or last line
  if ($top_bot == 0) {
    @menu_sub_title = (); $menu_sub_titler = "";
    $first_line = 2;			# Changing first menu line
  } else {
    @menu_bot_title = (); $menu_bot_titler = "";
    $last_line = $main'LINES - 3;	# Changing last menu line
  }

# Suck up file into a title string
  $i = 0;
  $concat_string = "";
  while (<INFILE>) { $concat_string .= $_; }
  close(INFILE);

# Process title string as normal into top/bottom titles
  if ($top_bot == 0) {
    $first_line += &proc_titles($concat_string,*menu_sub_title,
				*menu_sub_title_attr,*menu_sub_title_col);
  } else {
    $last_line  -= &proc_titles($concat_string,*menu_bot_title,
				*menu_bot_title_attr,*menu_bot_title_col);
    $last_line--;		# Blank line between menu and bottom titles
  }

# Re-calculate some key variables
  $arrow_line = $first_line;    # Arrow on top item by default
  $arrow_col = 0;

  0;
}

#*********
#  MENU_SETEXIT
#
#  Function:   Set the keys for exiting MENU_GETSTR 
#
#  Call format: &menu_setexit(@exit_key_array);
#			OR
#		&menu_setexit("exit_seq1","exit_seq2",...);
#
#  Arguments:  exit_key_array - the keys to end menu_getstr on
#********** 
sub menu_setexit { @menu_exitkeys = @_; }

#********** 
#  MENU_GETEXIT
#
#  Function:  Returns the key last used to exit menu_getstr
#
#**********
sub menu_getexit { return($menu_lastexit); }

#***********
#  PROC_TITLES
#
#  Function:	Process title string into sub-title/bottom title arrays.
#
#  Call format:	&proc_titles("String",*string_array,*attr_array,*col_array);
#
#  Arguments:	String presented in menu, array to load.
#
#  Returns:	Number of items loaded into the array.
#***********
sub proc_titles {
  local($title_strings,*temp_title,*temp_title_attr,*temp_title_col) = @_;
  local($i);

# If the title is a function, we will process it at display time.
  if ($title_strings =~ /^&/) {
    $temp_title[0] = substr($title_strings,1);
    $temp_title_col[0] = -1;
    $temp_title_attr[0] = -1;
    return(1);
  }

  @temp_title = split('\n',$title_strings);
  if ($#temp_title < 0) { return(0); }

  for ($i = 0; $i <= $#temp_title; $i++) {

    # Figure out rendition.
    $temp_title_attr[$i] = 0;
    if (substr($temp_title[$i],0,1) eq '-') {
      $temp_title[$i] = substr($temp_title[$i],1);
      $temp_title_attr[$i] = 1;
    }

    # Figure out justification.
    $justify = substr($temp_title[$i],0,1);
    if (($justify eq "<") || ($justify eq ">")) {
      $temp_title[$i] = substr($temp_title[$i],1);
    } else { $justify = ""; }

    if (length($temp_title[$i]) >= $main'COLS-1) {
      $temp_title[$i] = substr($temp_title[$i],0,$main'COLS-1);
      $temp_title_col[$i] = 0;
    } else {
      if ($justify eq "<") {
        $temp_title_col[$i] = 0;
      } elsif ($justify eq ">") {
        $temp_title_col[$i] = $main'COLS - length($temp_title[$i]) - 1;
      } else {
        $temp_title_col[$i] = int($main'COLS/2) - int(length($temp_title[$i])/2);
      }
    }
  }
  $i; # Return number of items processed
}

#***********
#  MENU_ITEM
#
#  Function:	Add an item to the active menu.
#
#  Call format:	&menu_item("What you see","test_rtn",pre_set_flag);
#
#  Arguments:	- String presented in menu. Required.
#		- String returned if selected. Optional.
#		- Value to pre-set multiple selection menu. Optional.
#		  (neg=lockout selection,0=allow selection,1=preset selection)
#
#  Returns:	Number of items currently in the menu.
#***********
sub menu_item {
  local($item_text,$item_sel,$item_set) = @_;

# Sanity check
  if ($item_lines_per_screen <= 0) { return(0); }
  if (!$item_text) { return($menu_index); }
  if (!$item_set) { $item_set = 0; }

  if (UNIVERSAL::isa($item_text, 'HASH')) {
    bless $item_text, 'perlmenu::label';
    start_color();
  }

# Adjust max length value (for centering menu)
  $_ = length("$item_text");
  if ($_ > $max_item_len) { $max_item_len = $_; }

# Load into arrays and adjust index
  $menu_sel_text[$menu_index] = $item_text;
  $menu_sel_action[$menu_index] = $item_sel;
  $selected_action[$menu_index] = $item_set;
  ++$menu_index;
}

#**********
#  MENU_DISPLAY 
#
#  Function:	Display items in menu_sel_text array, allow selection, and
#		return appropriate selection-string.
#
#  Call format:	$sel = &menu_display("Prompt text",$arrow_line,$top_item);
#
#  Arguments:   - Prompt text (for the bottom line of menu).
#		- Line number offset for the arrow (defaults to zero).
#		- Index of top item on screen (defaults to zero).
#		- Column number offset for the arrow (multiple-column mode
#		  only, defaults to zero).
#
#  Returns:     Selected action string (from second param on &menu_item)
#		%UP%    -- "u"|"U" pressed (or "t"|"T" and looking for top)
#               %EMPTY% -- Nothing in menu to display
#
#  Notes:	1) This routine ALWAYS sets "nocbreak" and "echo" terminal 
#		   modes before returning.
#		2) This routine exits directly (after calling the optional 
#		   "quit" routine) if "q"|"Q" is pressed.
#**********
sub menu_display {
  ($menu_prompt,$arrow_spec_row,$menu_top_item,$arrow_spec_col) = @_;
  local($ret);

# Check for no "menu_item" calls.
  $total_items = $#menu_sel_text + 1;
  if ($total_items <= 0) {
    &nocbreak();		# ALWAYS turn off "cbreak" mode
    &echo();		# ALWAYS turn on "echo"
    return("%EMPTY%");
  }

  &clear(); $xrow = $xcol = 0;
  $last_menu_top_item = -1;	# Force drawing of menu items
  $ret = menu_display_internal(0, $menu_prompt, 0);
  if ($#_ > 0) { $_[1] = $arrow_spec_row; }
  if ($#_ > 1) { $_[2] = $menu_top_item; }
  if ($#_ > 2) { $_[3] = $arrow_spec_col; }
  &menu_return_prep();
  $ret;
}

#**********
#  MENU_DISPLAY_RADIO 
#
#  Function:	Display items in "radio-button" style.
#
#  Call format:	$sel = &menu_display_radio("Prompt text","current","Done");
#
#  Arguments:   - Prompt text (for the bottom line of menu).
#               - Current setting (one of the "action-texts" that is the
#                 current setting.
#               - Text for "done with setting" top menu item 
#                 Optional - defaults to "(Accept this setting)"
#
#  Returns:     Selected action string (from second param on &menu_item)
#		%UP%    -- "u"|"U" pressed (or "t"|"T" and looking for top) 
#               %EMPTY% -- Nothing in menu to display
#
#  Notes:	1) This routine ALWAYS sets "nocbreak" and "echo" terminal 
#		   modes before returning.
#		2) This routine exits directly (after calling the optional 
#		   "quit" routine) if "q"|"Q" is pressed.
#**********
sub menu_display_radio {
  ($menu_prompt,$current,$done_text) = @_;

# Check for no "menu_item" calls.
  $total_items = $#menu_sel_text + 1;
  if ($total_items <= 0) {
    &nocbreak();		# ALWAYS turn off "cbreak" mode
    &echo();		# ALWAYS turn on "echo"
    return("%EMPTY%");
  }

  &clear(); $xrow = $xcol = 0;
  $last_menu_top_item = -1;	# Force drawing of menu items
  $arrow_spec_row = $arrow_spec_col = $menu_top_item = 0; # Reset

# Insert our top selection item (and adjust max length value)
  if ($done_text eq "") { $done_text = "(Accept this setting)"; }
  $_ = length("$done_text");
  if ($_ > $max_item_len) { $max_item_len = $_; }
  unshift(@menu_sel_text,$done_text);
  unshift(@menu_sel_action,"%DONE%");
  $menu_index++;

  while (1) {
    $ret = &menu_display_internal(1,$menu_prompt,$current);
    last if $ret eq "%DONE%";
    if ($ret eq "%UP%") {
      &menu_return_prep();
      return($ret);
    }
    $current = $ret;
  }
  &menu_return_prep();
  $current;
}

#**********
#  MENU_DISPLAY_MULT
#
#  Function:	Display items in "multiple selection" format.
#
#  Call format:	$sel = &menu_display_mult("Prompt text","Done");
#
#  Arguments:   - Prompt text (for the bottom line of menu)
#               - Text for "done with selections" top menu item 
#                 Optional - defaults to "(Done with selections)"
#
#  Returns:     Selected action string (from second param on &menu_item)
#		%UP%    -- "u"|"U" pressed (or "t"|"T" and looking for top) 
#               %NONE%  -- No items selected
#               %EMPTY% -- Nothing in menu to display
#
#  Notes:	1) This routine ALWAYS sets "nocbreak" and "echo" terminal 
#		   modes before returning.
#		2) This routine exits directly (after calling the optional 
#		   "quit" routine) if "q"|"Q" is pressed.
#**********
sub menu_display_mult {
  ($menu_prompt,$done_text) = @_;
  local($i,$ret) = 0;

# Check for no "menu_item" calls.
  $total_items = $#menu_sel_text + 1;
  if ($total_items <= 0) {
    &nocbreak();		# ALWAYS turn off "cbreak" mode
    &echo();		# ALWAYS turn on "echo"
    return("%EMPTY%");
  }

  &clear(); $xrow = $xcol = 0;
  $last_menu_top_item = -1;	# Force drawing of menu items
  $arrow_spec_row = $arrow_spec_col = $menu_top_item = 0; # Reset

# Insert our top selection item (and adjust max length value)
  if ($done_text eq "") { $done_text = "(Done with selections)"; }
  $_ = length("$done_text");
  if ($_ > $max_item_len) { $max_item_len = $_; }
  unshift(@menu_sel_text,$done_text);
  unshift(@menu_sel_action,"%DONE%");
  unshift(@selected_action,0);
  $menu_index++;

# Loop, allowing toggle of selections, until done.
  while (1) {
    $ret = &menu_display_internal(2,$menu_prompt,0);
    last if $ret eq "%DONE%";
    if (($ret eq "%UP%") || ($ret eq "%EMPTY%")) {
      @selected_action = (); 
      &menu_return_prep();
      return($ret);
    }
    if ($selected_action[$item] >= 0) {
      if ($selected_action[$item]) { $selected_action[$item] = 0; } #Toggle off
      else { $selected_action[$item] = 1; } # Toggle on
    } else { &bell(); }
  }

# Format the return string based on selections.
  $ret = "";
  $i = 1;  
  while ($i < $menu_index) {
    if ($selected_action[$i] > 0) { $ret .= "$menu_sel_action[$i],"; }
    $i++;
  }
  chop($ret);       # Remove final comma
  @selected_action = ();
  if ($ret eq "") { $ret = "%NONE%"; }
  &menu_return_prep();
  $ret;
}

#**********
#  MENU_GETSTR
#
#  Function:	Prompt for a string (allowing editing) from one row of the
#		screen.
#
#  Call format:	$string = &menu_getstr(row,col,"Prompt text",clr_flag,
#					"Initial value",maxlen,noshow,
#					data-type,window);
#
#  Arguments:	- Row,Col for prompt and data-input. Required.
#		- Prompt text. Optional. Default="";
#		- Boolean flag (0=leave line on exit, 1=clear line on exit)
#		  Optional.  Default=0.
#		- Initial value. Optional. Default="".
#		- Max length of input field. Optional.
#		- Boolean flag (0=show,1=hidden) (use "hidden" for passwords)
#		  Optional.  Default=0.
#		- Data-type (0=alphanumeric,1=numeric).  Optional. Default=0.
#		- Window value. Optional.  Default=main window.
#		- Cursor position (not offset).  Optional.
#		  Default=end of "Initial value".
#
#  Returns:     String (can be null)
#
#  Notes:       1) This routine ALWAYS sets "nocbreak" and "echo" terminal
#                  modes before returning.
#		2) This routine checks for the right edge of the screen.
#**********
sub menu_getstr {
  local($row,$col,$prompt,$cleanup,$default,$maxlen,$noshow,$dtype,$win,$cpos)
	= @_;
  local($prompt_col,$left_col,$action,$string,$i,$overstrike);
  local ($stars);

  if (!$win) { $win = $window; } # Use main window by default

# Set cbreak, noecho.
  &cbreak();
  &noecho();

# Make sure the default is not longer than the maximum lengths
  if (($maxlen > 0) && (length($default) > $maxlen)) {
    $default = substr($default,0,$maxlen);
  }
  
# Clear our area. Place prompt and any default on the screen
  &wmove($win,$row,$col);
  &wclrtoeol($win);
  if ($prompt ne "") { &waddstr($win,$prompt); }
  if ($default ne "") {
    if ($noshow) { 
      for ($i = 0; $i < length($default); $i++) { &waddstr($win,"*"); }
    } else { &waddstr($win,$default); }
  }

# Position cursor for data input
  $prompt_col = $col;
  $left_col = $prompt_col + length($prompt);
  if (!$cpos) { $col = $left_col + length($default); }
  else { $col = $cpos - 1; }
  &wmove($win,$row,$col);
  &wrefresh($win);

# Set max col to right edge of screen if maxlen passed.
# If single character field, allow "overstrike" mode.
  if ($maxlen == 0) { $maxcol = $main'COLS; }
  else { $maxcol = $prompt_col + length($prompt) + $maxlen; }
  if ($maxcol - $left_col == 1) { $overstrike = 1; }
  else { $overstrike = 0; }

  $string = $default;
  if (!$cpos) { $i = length($string); }
  else { $i = $cpos - 1; }

  $menu_lastexit = "\n";

# Perform editing until "Return" pressed.
  while (1) {
    $action = &collect_seq($win);

    if ($#menu_exitkeys >= 0) { &check_exit_keys(); } # Check any exit keys

    if (($action eq $kr) || ($action eq $ansi_kr)
	|| ($action eq $next_char) ) {	                # Right-arrow
      if ($i+1 > length($string)) { &bell(); }
      else {
	$col++; $i++;
	&wmove($win,$row,$col);
      }
    }
    elsif (($action eq $kl) || ($action eq $ansi_kl)
	   || ($action eq $prev_char) ) {		# Left-arrow
      if ($i-1 < 0) { &bell(); }
      else {
	$col--; $i--;
	&wmove($win,$row,$col);
      }
    }
    elsif (($action eq "\177") || ($action eq "\010")) {	# Delete/BS
      if ($i-1 < 0) { &bell(); }
      else {
	$col--; $i--;
	&wmove($win,$row,$col);
	&wdelch($win);
	$string = substr($string,0,$i).substr($string,$i+1);
      }
    }
    elsif ($action eq $delete_right) {				# Delete right
      if ($i < length($string)) {
	&wdelch($win);
	$string = substr($string,0,$i).substr($string,$i+1);
      }
      else { &bell(); }
    }
    elsif (($action eq $cr) || ($action eq $nl) || 
	   ($action eq "\n")) {					# Terminate
      $last_window_cpos = $col + 1;	# Save current column (not offset)
      if ($cleanup) {
	&wmove($win,$row,$prompt_col);	# Clear our stuff
	&wclrtoeol($win);
	&wrefresh($win);
      }
      &nocbreak();		# ALWAYS turn off "cbreak" mode
      &echo();		# ALWAYS turn on "echo"
      return($string);
    }
    elsif (($action eq $ku) || ($action eq $ansi_ku) ||
           ($action eq $next_field) || ( $action eq $prev_field ) ||
	   ($action eq $kd) || ($action eq $ansi_kd)) {
      ; # Ignore
    } 
    elsif ($action eq $begin_of_line) {		# Go to begin-of-line
      $col = $prompt_col + length($prompt); $i=0;
      &wmove($win,$row,$col);
    }
    elsif ($action eq $end_of_line) {		# Go to end-of-line
      $col = $prompt_col + length($prompt) + length($string);
      $i   = length($string);
      &wmove($win,$row,$col);
    }
    elsif ($action eq $kill_line) {		# Delete to end-of-line
      if ($i != length($string)) { # Not at end of line
	&wclrtoeol($win);
	$kill_buffer = substr($string,$i);
	$string = substr($string,0,$i)
      } else { &bell(); }
    }
    elsif ($action eq $yank_line) {		# Paste killed text
      # Now it "does the right thing" in numeric-only 
      # and hidden fields
      if (length($kill_buffer) != 0) { 
	# Check for non-numeric kill_buffer in numeric-only field
	if ($dtype == 1 && $kill_buffer !~ m/^\d+$/ ) { &bell(); }
	elsif ($overstrike) {
	  # If single-character field cannot yank a multi-character field
	  if (length($kill_buffer) != 1) { &bell(); }
	  else {
	    # Delete single-character field
	    &wmove($win,$row,$col);
	    &wdelch($win);
	    # Yank single-character kill_buffer
	    &winsch($win,ord($kill_buffer));
            $string = $kill_buffer;
	  }
	}
	elsif ($left_col + length($string) + length($kill_buffer) > $maxcol) { 
	  # Yanking kill_buffer will make field too long
	  &bell(); 
	}
	else {
	  if ($noshow) {
	    $stars = '*' x length($kill_buffer);
	    # Draw yanked text
	    &waddstr($win,$stars."\0");
	    # Draw rest of string
	    $stars = '*' x length(substr($string,$i));
            &waddstr($win,$stars."\0");
	  }
	  else {
            # Draw yanked text
	    &waddstr($win,$kill_buffer."\0");
	    # Draw rest of string
	    &waddstr($win,substr($string,$i)."\0");
          }
	  $string = substr($string,0,$i) . $kill_buffer . substr($string,$i);
	  $col += length($kill_buffer);
	  $i   += length($kill_buffer);
	  &wmove($win,$row,$col);
       }
     }
    }
    else { # Any other character
      if ($overstrike) {	# Delete only char on single-char field
	&wmove($win,$row,$col);
	&wdelch($win);
	$string = "";
      }
      if ($left_col + length($string) + 1 > $maxcol) { &bell(); }
      else {
	if (($dtype == 1) && (index("0123456789",$action) < 0)) { &bell(); }
	else {
	  &wmove($win,$row,$col);	# Insert the character on the screen
	  if ($noshow) { &winsch($win,ord("*")); }
	  else { &winsch($win,ord($action)); }
	  $string = substr($string,0,$i).$action.substr($string,$i);
	  if (!$overstrike) {
	    $col++; $i++;
	    &wmove($win,$row,$col);
	  }
	}
      }
    }
    &wrefresh($win);
  }
}

#**********
#  MENU_DISPLAY_INTERNAL 
#
#  Function:	Display items in menu_sel_text array, allow selection, and
#		return appropriate selection-string.
#
#  Call format:	$sel = &menu_display_internal([0|1|2],"Prompt text",
#			$arrow_pos,$top_item,"current");
#
#  Arguments:   - Menu type (0=simple, 1=radio, 2=multiple-select).
#               - Prompt text (for the bottom line of menu).
#		- Current selection (radio only).
#
#  Returns:     Selected action string (from second param on &menu_item)
#		%UP%    -- "u"|"U" pressed (or "t"|"T" and looking for top)
#               %EMPTY% -- Nothing in menu to display
#               %DONE%  -- Done with selections (radio and mult only)
#**********
sub menu_display_internal {
  ($menu_type,$menu_prompt,$radio_sel) = @_;
  local($i,$search,$low_sel,$do_scroll,$move_amt);

# If looking for top menu, return with "%UP%".
  if ($finding_top) {
    if ($menu_is_top_one) { $finding_top = 0; } 
    else { return("%UP%"); }
  }

# Check for no "menu_item" calls.
  $total_items = $#menu_sel_text + 1;
  if ($total_items <= 0) {
    &nocbreak();		# ALWAYS turn off "cbreak" mode
    &echo();		# ALWAYS turn on "echo"
    return("%EMPTY%");
  }

  &cbreak();		# cbreak mode (each character available)
  &noecho();		# Menus are always "noecho"

# Compute prepend length (for stuff we prepend to each selection text)
  $prepend_len = 0;				# Assume nothing
  if (!$highlight && $menu_numbered) { $prepend_len += 2; } # Adjust for "->"
  if ($menu_numbered) { $prepend_len += 6; }	# Adjust for "nnnn) "
  if ($menu_type) { $prepend_len += 4; }	# Adjust for "[X] "

# Calculate items per line and items per screen (based on mult-column pref)
  if ($multiple_column) {
    $column_width = $prepend_len + $max_item_len + 1; # Always pad one blank
    $items_per_line = int(($main'COLS-1)/$column_width);
    if ($items_per_line <= 0) { $items_per_line = 1; }
  } else {
    $column_width = $prepend_len + $max_item_len;
    $items_per_line = 1;
  }
  $items_per_screen = ($last_line - $first_line + 1) * $items_per_line;

  if ($total_items <= $items_per_screen) { $menu_single_page = 1; }
  else { $menu_single_page = 0; }

  if ($menu_prompt eq "") {
    $menu_prompt = "h)elp";
    if ($menu_item_help_routine ne "") { $menu_prompt .= " ?)item-help"; }
    if (!$disable_quit) { $menu_prompt .= " q)uit"; }
    $menu_prompt .= " u)p";

    if ($menu_top_activated) {
      if (! $menu_is_top_one) { $menu_prompt .= " t)op"; }
    }
    if ($menu_type == 2) { $menu_prompt .= " a)ll m)atch c)lear"; }
    if (! $menu_single_page) {
      $menu_prompt .= " n)ext-pg p)rev-pg";
    }
    $menu_prompt .= " b)egin e)nd";
    if (length($menu_prompt)+9 < $main'COLS - 7) {
      $menu_prompt .= " r)efresh";
    }
  }
  if (length($menu_prompt) > $main'COLS - 7) {
    $menu_prompt = substr($menu_prompt,0,$main'COLS - 7);
  }

# Validate/adjust paramaters.
  $arrow_line = $arrow_spec_row + $first_line;
  if ($menu_top_item + 1 > $total_items) { $menu_top_item = $total_items - 1; }
  if ($arrow_line < $first_line) { $arrow_line = $first_line; }
  if ($arrow_line > $last_line) { $arrow_line = $last_line; }

  $arrow_col = $arrow_spec_col;
  if ($arrow_col < 0) { $arrow_col = 0; }
  elsif ($arrow_col > $items_per_screen - 1) {
    $arrow_col = $items_per_screen - 1;
  }

# Compute leftmost column (for left-justified or centered menus)
  $left_margin = 0; # Assume left-justified menu (no centering)
  if ($center_menus) {
    $left_margin = int($main'COLS/2) - int($column_width/2) * items_per_line;
  }

# Clear screen and add top title and bottom prompt
  &menu_top_bot();
  $move_amt = 0;
  $number = 0;
  $menu_lastexit = "\n";
   
  while (1) {
    $number_shown = $menu_top_item + $items_per_screen;
    if ($number_shown > $total_items) { $number_shown = $total_items; }
    $percent = int($number_shown * 100 /$total_items);

    &menu_page();		# Display current page

# Collect key sequences until something we recoginize 
# (or we know we don't care)
    $action = &collect_seq($window);

    if ($#menu_exitkeys) { &check_exit_keys(); } # Check any exit keys

# If trying to be more "gopher-like", translate now.
    if ($gopher_like && ($items_per_line == 1)) {
      if (($action eq $kr) || ($action eq $ansi_kr)) { $action = "\n"; }
      if (($action eq $kl) || ($action eq $ansi_kl)) { $action = "u"; }
    }

# Perform action based on keystroke(s) received
    $move_amt = 0;
    if ($action ne "") {
      $last_arrow_line = $arrow_line;
      $last_arrow_col = $arrow_col;
      if (($action eq $kd) || ($action eq $ansi_kd)) {		# Down-arrow
        $number = 0;
	$do_scroll = 1;
	if ($items_per_line > 1) {
	  if (($arrow_line+1 >= $max_sel_line) && ($arrow_col > $max_sel_col)) {
	    $do_scroll = 0;
	  }
	}
	if ($do_scroll) {
	  if ($arrow_line < $max_sel_line) { $arrow_line++; }
	  else {
	    if ($gopher_like) {
	      $move_amt = $items_per_screen;
	      $arrow_line = $first_line;
	    } else {
	      if ($arrow_line == $last_line) { $move_amt = $items_per_line; }
	    }
	  }
	}
      }
      if (($action eq $next_field) || ($action eq $kr) ||
	  ($action eq $ansi_kr)) {				# Right-arrow
        $number = 0;
	$do_scroll = 1;
	if ($items_per_line > 1) {
	  if (($arrow_line == $max_sel_line) && ($arrow_col == $max_sel_col)) {
	    $item = $menu_top_item+($arrow_line-$first_line)*$items_per_line+$arrow_col;
	    if (($item == $menu_index-1) && !$gopher_like) { $do_scroll = 0; }	
	  } else {
	    if ($arrow_col + 1 < $items_per_line) {
	      $arrow_col++;
	      $do_scroll = 0;
	    }
	  }
	}
	if ($do_scroll) {
	  $arrow_col = 0;
	  if ($arrow_line < $max_sel_line) { $arrow_line++; }
	  else {
	    if ($gopher_like) {
	      $move_amt = $items_per_screen;
	      $arrow_line = $first_line;
	    } else {
	      if ($arrow_line == $last_line) { $move_amt = $items_per_line; }
	    }
	  }
	}
      }
      elsif (($action eq $ku) || ($action eq $ansi_ku)) {	# Up-arrow
        $number = 0;
        if ($arrow_line > $first_line) { $arrow_line--; }
        else {
	  if ($gopher_like) {
	    $move_amt = -$items_per_screen;
	    if ($menu_top_item + $move_amt < 0) { # Moving before 1st item
	      if ($menu_top_item > 0) { # Not currently on 1st page
		$arrow_line = $menu_top_item + $arrow_line - 1; # Adjust arrow
	      } else { $arrow_line = $last_line; }
	    } else { $arrow_line = $last_line; }
	  } else { $move_amt = -$items_per_line; }
	}
      }
      elsif (($action eq $prev_field) || ($action eq $kl) ||
	     ($action eq $ansi_kl)) {				# Left-arrow
        $number = 0;
	$do_scroll = 1;
	if ($items_per_line > 1) {
	  if ($arrow_col > 0) {
	    $arrow_col--;
	    $do_scroll = 0;
	  } else {
	    if (($arrow_line > $first_line) || ($menu_top_item > 0)) {
	      $arrow_col = $items_per_line - 1;
	    } else {
	      if ($gopher_like) { $arrow_col = $max_sel_col; }
	      else { $do_scroll = 0; }
	    }
	  }
	}
	if ($do_scroll) {
	  if ($arrow_line > $first_line) { $arrow_line--; }
	  else {
	    if ($gopher_like) {
	      $move_amt = -$items_per_screen;
	      if ($menu_top_item + $move_amt < 0) { # Moving before 1st item
	        if ($menu_top_item > 0) { # Not currently on 1st page
		  $arrow_line = $menu_top_item + $arrow_line - 1; # Adjust arrow
	        } else { $arrow_line = $last_line; }
	      } else { $arrow_line = $last_line; }
	    } else { $move_amt = -$items_per_line; }
	  }
	}
      }
      elsif (($action eq "n") || ($action eq "N") ||		# Next
	     ($action eq " ")) {
        $number = 0;
	$move_amt = $items_per_screen;
      }
      elsif (($action eq "b") || ($action eq "B")) {		# Begin
        $menu_top_item = 0;
	$arrow_line = $first_line;
	$arrow_col = 0;
	$number = 0;
      }
      elsif (($action eq "e") || ($action eq "E")) {		# End
	$number = 0;
	if (! $menu_single_page) {
	  $menu_top_item = $menu_index - $items_per_screen;
	}
	$arrow_line = $last_line;
	$arrow_col = $max_sel_col;
      }
      elsif (($action eq "p") || ($action eq "P")) {		# Previous
        $number = 0;
	$move_amt = -$items_per_screen;
      }
      elsif (($action eq "a") || ($action eq "A")) {		# Select all
	if ($menu_type == 2) {
	  $i = 1;  
	  while ($i < $menu_index) {
	    if ($selected_action[$i] >= 0) { $selected_action[$i] = 1; }
	    $i++;
	  }
	}
      }
      elsif (($action eq "c") || ($action eq "C")) {		# Clear all
	if ($menu_type == 2) {
	  $i = 1;  
	  while ($i < $menu_index) {
	    if ($selected_action[$i] >= 0) { $selected_action[$i] = 0; }
	    $i++;
	  }
	}
      }
      elsif (($action eq "m") || ($action eq "M") ||		# Match string
             ($action eq "=") || ($action eq "/")) {
	if ($menu_type == 2) {
	  $search = &menu_getstr($last_line+1,0,"Search string: ",1);
	  &cbreak();		# menu_getstr turned this off
	  &noecho();		# menu_getstr turned this on
	  if ($search) {		# Toggle selections
	    $search =~ tr/A-Z/a-z/;
	    $i = 1;  
	    while ($i < $menu_index) {
	      if ($selected_action[$i] >= 0) {
	        $low_sel = "$menu_sel_text[$i]";
	        $low_sel =~ tr/A-Z/a-z/;
	        if (index($low_sel,$search) >=0) { $selected_action[$i] = 1; }
	      }
	      $i++;
	    }
	  }
	}
      }
      elsif (($action eq "r") || ($action eq "R") ||
	     ($action eq $redraw_screen)) {			# Refresh
	  &clear();
	  &menu_top_bot();
	  $last_menu_top_item = -1;
	  &menu_page();
      }
      elsif (($action eq "\177") || ($action eq "\010")) {	# Delete/BS num-reset
	  $number = 0;
	  $arrow_line = $first_line;
	  &menu_page();
      }
      elsif ((($action eq "Q")||($action eq "q")) && !$disable_quit) { # Quit
	&clear(); $xrow = $xcol = 0;
	&move(0,0);
	if ($quit_prompt eq "") { $ch = "Do you really want to quit?"; }
	else { $ch = $quit_prompt; }
	$ch .= " $quit_default";
	&addstr($ch);
	&move(0,length($ch) - 1);
	&refresh();
	$ch = &getch();
	if ($ch eq "") { &menu_hangup_proc(); }
	if (($ch eq $cr) || ($ch eq $nl) || ($ch eq "\n")) {
	  $ch = $quit_default;
	}
	$ch =~ tr/A-Z/a-z/;
	if ($ch eq "y") {
	  &menu_return_prep();
	  if ($menu_exit_routine ne "") { &$menu_exit_routine(); }
	  exit(0);
	}
	&clear(); $xrow = $xcol = 0;
	&menu_top_bot();	# Re-display current page
	$last_menu_top_item = -1;
	&menu_page();
      }
      elsif (($action eq "U") || ($action eq "u")) {		# Up
	unless ($menu_is_top_one) {
	  $finding_top = 0;
	  return("%UP%");
	}
      }
      elsif (($action eq "T") || ($action eq "t")) {		# Top
        if ($menu_top_activated && !$menu_is_top_one) {
	  $finding_top = 1;
	  return("%UP%");
	}
      }
      elsif (($action eq "h") || ($action eq "H") ||		# Help
	     ($action eq "?")) {
	if (($action eq "?") && ($menu_item_help_routine ne "")) {
	  if ($number) { $item = $number - 1; }
	  else { $item = $menu_top_item+($arrow_line-$first_line)*$items_per_line+$arrow_col; }
	  if (($item < $menu_top_item) || ($item > $menu_bot_item)) { 
	    &bell();
	    $number = 0;
	  }
	  else {
	    &$menu_item_help_routine("$menu_sel_text[$item]",$menu_sel_action[$item]);
	    &clear(); &refresh();
	  }
	} else {
	  &$menu_generic_help_routine();	# Show generic help page
	  &clear(); $xrow = $xcol = 0;
	  &refresh(); 
	}
	&menu_top_bot();	# Clear and re-display the current page
	$last_menu_top_item = -1;
	&menu_page();
      }
      elsif ($action eq "!") {					# Shell escape
	if ($menu_shell_text ne "") {
	  &clear(); $xrow = $xcol = 0;	# Clear screen
	  &refresh();
	  &nocbreak();	# ALWAYS turn off "cbreak" mode
	  &echo();		# ALWAYS turn on "echo"
	  $xrow = $xcol = 0;
	  &print_nl("Entering command shell via \"$menu_shell_text\".",1);
	  &print_nl("Return here via shell exit (normally Control-D).",1);
	  &refresh();
	  &endwin();
	  system($menu_shell_text);
	  &cbreak();	# cbreak mode (each character available)
	  &noecho();	# Menus are always "noecho"
	  &clear(); $xrow = $xcol = 0;	# Clear screen
	  &menu_top_bot();	# Re-display the current page
	  $last_menu_top_item = -1;
	  &menu_page();
	}
      }
      elsif (($action eq $cr) || ($action eq $nl) || 
	     ($action eq "\n")) {				# RETURN
	if ($number) { $item = $number - 1; }
	else { $item = $menu_top_item+($arrow_line-$first_line)*$items_per_line+$arrow_col; }
	if (($item < $menu_top_item) || ($item > $menu_bot_item)) {
	  &bell();
	  $number = 0;
	}
	else {
          $arrow_spec_row = $arrow_line - $first_line;
	  $arrow_spec_col = $arrow_col;
	  return($menu_sel_action[$item]);
	}
      }
      else {
	$digit_val = index("0123456789",$action);		# Number
	if ($digit_val >= 0) {
	  $number = $number * 10 + $digit_val;
	  if ($number >= $menu_top_item + 1) { 
	    if (($number <= $menu_bot_item + 1) && ($number <= $total_items)) {
	      if ($items_per_line > 1) {
		$i = $number - $menu_top_item - 1;
		$arrow_line = int($i/$items_per_line) + $first_line;
		$arrow_col = $i % $items_per_line;
	      } else {
		$arrow_line = $number - $menu_top_item + $first_line - 1;
	      }
	    } else {
	      &bell();
	      $number = 0;
	      $arrow_line = $first_line; $arrow_col = 0;
	    }
	    &menu_page();
	  }
	}
      }

# Check for paging/scrolling of the menu text.
# Key variable to set is "menu_top_item".
      if ($move_amt != 0) {
	if ($move_amt < 0) {		# Move backward
	  if ($menu_top_item + $move_amt < 0) { # Moving before 1st item
	    if ($gopher_like) {
	      if ($menu_top_item > 0) { # Not currently on 1st page
		$menu_top_item = $menu_top_item + $move_amt;
	      } else { # Currently on 1st page
		$menu_top_item = $total_items - $items_per_screen;
	      }
	      if ($menu_top_item < 0) { $menu_top_item = 0; }
	    } else { $menu_top_item = 0; }
	  } else { $menu_top_item = $menu_top_item + $move_amt; } 
	}
	else {				# Move forward
	  if (($menu_top_item + $move_amt < $total_items) &&
	      ($menu_bot_item + 1 < $total_items)) {
	    $menu_top_item = $menu_top_item + $move_amt;
	  } else {
	    if ($gopher_like) { $menu_top_item = 0; }
	  }
	} 
      }

# Reset last selection to normal rendition or clear last arrow
      if ($highlight) {
        $item = $menu_top_item + ($last_arrow_line - $first_line) *
                $items_per_line + $last_arrow_col;
        $i = $left_margin + $prepend_len + $last_arrow_col * ($column_width);
        if ($menu_type && !$item) {
          $i -= 4; # No "[X] " on first item
        }
        move($last_arrow_line, $i);

        addstr("$menu_sel_text[$item]"); # double quote to force stringify!
        move($last_arrow_line, $i);
      }
      else {
        if ($menu_numbered) {
          move($last_arrow_line,$left_margin+$last_arrow_col*($column_width));
          addstr('  ');
        }
      }
    }
  }
}

#*********
# CHECK_EXIT_KEYS
#
# Function:  Check for user-define exit keys on menu and getstr.
#
# Input:     Nothing
#
# Returns:   Nothing (action and lastexit set)
#
#*********
sub check_exit_keys {
  local($j);

  for ($j = 0; $j <= $#menu_exitkeys; $j++) {
    if ($action eq $menu_exitkeys[$j]) {
      $menu_lastexit = $action;
      $action = "\n";
      last;
    }
  }
}

#**********
# COLLECT_SEQ -- Collect characters until a sequence we recognize (or we
#		 know it cannot possibly fit any "magic" sequences.
#**********
sub collect_seq {
  local($cwin) = @_;
  local($i,$possible);
  local($collect,$action) = "";

  $possible = $#magic_seq;	# Set number of possible matches 

seq_seek:
  while ($possible > 0) {
    $ch = &wgetch($cwin);
    if ($ch eq "") { &menu_hangup_proc(); }
    $collect = $collect.$ch;
    $i = 0;
    $possible = 0;
    $action = $ch;
try:
    while ($i <= $#magic_seq) {
      if (length($collect) > length($magic_seq[$i])) {
	$i++;
	next try;
      }
      if (substr($magic_seq[$i],0,length($collect)) eq $collect) {
        $possible++;
	if ($collect eq $magic_seq[$i]) {
          $action = $magic_seq[$i];
          last seq_seek;
        }
      }
      $i++;
    } # end while
  }
  $action;
}

#**********
#  MENU_TOP_BOT -- Display top and bottom lines of current menu
#**********
sub menu_top_bot {
  local($i,$j,$temp);

# Main top title
  &move(0,$menu_top_title_col);
  if ($menu_top_title_attr == 0) { &standout(); }
  &addstr($menu_top_title);
  if ($menu_top_title_attr == 0) { &standend(); }

# Top sub-titles
  if ($menu_sub_titler ne "") {
    $temp = &$menu_sub_titler;		# Expand title string
    $first_line = 2;			# Assume no sub-titles for now
    $last_line = $main'LINES - 3;	# Assume no bottom-titles for now
    if ($temp ne "") {
      $first_line += &proc_titles($temp,*menu_sub_title,
				*menu_sub_title_attr,*menu_sub_title_col);
    } else {
      @menu_sub_title = ();
    }
  }
  if ($#menu_sub_title >= 0) {
    for ($i = 0; $i <= $#menu_sub_title; $i++) {
      &move($i+1,$menu_sub_title_col[$i]);
      if ($menu_sub_title_attr[$i] == 0) { &standout(); }
      &addstr($menu_sub_title[$i]);
      if ($menu_sub_title_attr[$i] == 0) { &standend(); }
    }
  }

# Bottom sub-titles
  if ($menu_bot_titler ne "") {
    $temp = &$menu_bot_titler;
    if ($temp ne "") {
      $last_line = $main'LINES - 3;
      $last_line  -= &proc_titles($temp,*menu_bot_title,
				*menu_bot_title_attr,*menu_bot_title_col);
      $last_line--;	# Blank line between menu and bottom titles
    } else {
      @menu_bot_title = ();
    }
  }
  if ($#menu_bot_title >= 0) {
    $j = $main'LINES - $#menu_bot_title - 3;
    for ($i = 0; $i <= $#menu_bot_title; $i++) {
      &move($j+$i,$menu_bot_title_col[$i]);
      if ($menu_bot_title_attr[$i] == 0) { &standout(); }
      &addstr($menu_bot_title[$i]);
      if ($menu_bot_title_attr[$i] == 0) { &standend(); }
    }
  }

  $items_per_screen = ($last_line - $first_line + 1) * $items_per_line;
  &move($main'LINES - 1,7);
  &addstr($menu_prompt);
}

#**********
#  MENU_PAGE -- Display one page of menu selection items.
#**********
sub menu_page {
  local($i,$j) = 0;
  local($curr_line,$line,$fx,$iw);
  local($refresh_items) = 0;

# Check for top item change (scrolling/paging of menu text).
  if ($menu_top_item != $last_menu_top_item) {
    $last_menu_top_item = $menu_top_item;
    $refresh_items = 1;
  }

# Refresh all items on screen
  if ($refresh_items) {
    # Update percentage on bottom line
    &move($main'LINES-1,0);
    &standout();
    if ($menu_single_page) {
      addstr('(All) ');
    }
    else {
      addstr(sprintf("\(%3d%%\)",$percent));
    }
    &standend();
 
    # Display current page of menu
    $item = $menu_top_item;
    $menu_bot_item = $menu_top_item;
    $curr_line = $first_line;
    $max_sel_line = $first_line;
    $max_sel_col = 0;

    while ($curr_line <= $last_line) { # Process lines on screen
      &move($curr_line,$left_margin);
      &clrtoeol();
      $line = "";

      if ($item < $total_items) { # If any items left to show ...
        $curr_col = 1;
        while ($curr_col <= $items_per_line) { # Add items to line
          if ($item < $total_items) {
            if ($menu_numbered) {
              $line .= &menu_add_number($item + 1);
            }
            if ($menu_type) { # Add selection boxes on mult/radio
              if ($item != 0) {
                if ($menu_type == 1) {
                  if ($menu_sel_action[$item] eq $radio_sel) {
                    $line .= '[X] ';
                  }
                  else {
                    $line .= '[ ] ';
                  }
                }
                else { # menu_type is 2
                  if ($selected_action[$item] > 0) {
                    $line .= '[X] ';
                  }
                  elsif ($selected_action[$item] < 0) {
                    $line .= '[-] ';
                  }
                  else {
                    $line .= '[ ] ';
                  }
                }
              }
            }

            $line .= "$menu_sel_text[$item]"; # Add the selection text

            if ($items_per_line > 1) { # Pad out if multiple columns
              $i = 1; # Always pad one
              if ($menu_type && !$item) {
                $i += 4; # Missing "[ ] "
              }
              $line .= ' ' x ($max_item_len-length("$menu_sel_text[$item]")+$i);
            }
            $max_sel_col = $curr_col - 1;
            $item++;
          }
          $curr_col++;
        }

        if (length($line) > $main'COLS - 1) { # Truncate lines that would wrap
          $line = substr($line,0,$main'COLS - 1);
        }

        my $label = $menu_sel_text[$item - 1]; # KLUGE; $item got incremented above

        attrset(COLOR_PAIR(0));
        if (eval { $label->isa('perlmenu::label') }) {
          my $preline = substr($line, 0, -(length $label->{text}));
          addstr($preline);

          my $attr = $label->{attr} || 0;

          if (defined($label->{fg}) && defined($label->{bg})) {
            my $n = create_color_pair($label->{fg}, $label->{bg});
            $attr = $attr | COLOR_PAIR($n);
          }

          attron($attr) if $attr;
          addstr($label->{text});
          attroff($attr) if $attr;
        }
        else {
          addstr($line);
        }

        attrset(COLOR_PAIR(0));
        $max_sel_line = $curr_line;
      }
      $curr_line++;
    }
    $menu_bot_item = $item - 1;
  } 
# Refresh only selection tags on radio/multi-select menus
  elsif ($menu_type) {
    $item = $menu_top_item;
    $curr_line = $first_line;
    while ($curr_line <= $last_line) {
      $i = $left_margin + $prepend_len - 3; # First "X" on line
      if ($item < $total_items) {
        for ($j = 0; $j < $items_per_line; $j++) {
          if ($item) {
            &move($curr_line,$i);
            if ($menu_type == 1) {
              if ($menu_sel_action[$item] eq $radio_sel) {
                addstr('X');
              }
              else {
                addstr(' ');
              }
            }
            else { # menu_type is 2
              if ($selected_action[$item] > 0) {
                addstr('X');
              }
              elsif ($selected_action[$item] < 0) {
                addstr('-');
              }
              else {
                addstr(' ');
              }
            }
          }
          $i += $column_width; # Next "X" on line
          $item++; # Next item
        }
      }
      $curr_line++; # Next line
    }
  }
 
# Sanity checks for arrow
  if ($arrow_line < $first_line) {
    $arrow_line = $first_line;
  }
  if ($arrow_line > $max_sel_line) {
    $arrow_line = $max_sel_line;
  }

# Highlight selection text or add selection arrow (based on prefs).
# Position the cursor properly on the screen.
  if ($highlight) {
    $item = $menu_top_item+($arrow_line-$first_line)*$items_per_line+$arrow_col;
    $i = $left_margin+$prepend_len+$arrow_col*($column_width);
    if ($menu_type && $item == 0) { $i -= 4; } # No "[X] " on first item
    &move($arrow_line,$i);
    &standout();
    addstr("$menu_sel_text[$item]"); # double quote to force stringify
    &standend();
    &move($arrow_line,$i);
  }
  else {
    move($arrow_line, $left_margin + $arrow_col * $column_width);
    if ($menu_numbered) {
      addstr('->');
    }
  }

# Write out current menu page
  &refresh();
}

#**********
# MENU_ADD_NUMBER -- Format selection number.
#**********
sub menu_add_number {
  local($sel_num) = @_;
  local($sel_str) = "";

  if (!$highlight) { $sel_str = "  "; }		# Place for "->"
  if ($sel_num < 1000) { $sel_str .= " "; }
  if ($sel_num < 100) { $sel_str .= " "; }
  if ($sel_num < 10) { $sel_str .= " "; }
  $sel_str .= "$sel_num) ";
  $sel_str;
}

#**********
# MENU_RETURN_PREP -- Common return functions.
#**********
sub menu_return_prep {
  &nocbreak();
  &echo(); 
  &clear();  $xrow = $xcol = 0;
  &refresh(); 
  if (!$curses_application) { &endwin(); }
}

#**********
# MENU_HANGUP_PROC -- Hangup return functions
#**********
sub menu_hangup_proc {
  if ($menu_exit_routine ne "") { &$menu_exit_routine(); }
  exit(1);
}

#**********
# MENU_DEFAULT_SHOW_HELP
#*********
sub menu_default_show_help {
  local($arrow_txt);

  &clear(); $xrow = $xcol = 0;
  &print_nl("--------------------------------",1);
  &print_nl("Menu Help (PerlMenu version 4.0)",1);
  &print_nl("--------------------------------",2);
  if ($items_per_line > 1) { $arrow_txt = "up/down/left/right"; }
  else { $arrow_txt = "up/down"; }
  if ($highlight) {
    &print_nl("- Use $arrow_txt arrow keys to highlight your selection.",1);
  } else {
    &print_nl("- Use $arrow_txt arrows to place \"->\" in front of your selection.",1);
  }
  if ($menu_type == 1) {
    &print_nl("- Press Return (or Enter) to choose that selection.",1);
    &print_nl("- Select the first item when ready to continue.",2);
  }
  elsif ($menu_type == 2) {
    &print_nl("- Press Return (or Enter) to toggle the selection on/off.",1);
    &print_nl("- Select the first item when ready to continue.",2);
  } else {
    &print_nl("- Press Return (or Enter) when ready to continue.",2);
  }
  &print_nl("Available action-keys:",1);
  &print_nl("h - Show this help screen.",1);
  if ($menu_item_help_routine ne "") {
    if ($highlight) {
      &print_nl("? - Show help on the item with the \"->\" in front.",1);
    } else {
      &print_nl("? - Show help on the highlighted item.",1);
    }
  }
  if (!$disable_quit) {
    &print_nl("q - Quit entirely.",1);
  }
  &print_nl("u - Return to the previous menu or function.",1);
  if ($menu_top_activated && !$menu_is_top_one) {
    &print_nl("t - Return to the top menu.",1);
  }
  if ($menu_type == 2) {
    &print_nl("a - Select all items.",1);
    &print_nl("m - Select based on a case-insensitive string match.",1);
    &print_nl("c - Clear all selections.",1);
  }
  if (! $menu_single_page) {
    &print_nl("n - Move forward to next page.",1);
    &print_nl("p - Move backward previous page.",1);
  }
  &print_nl("b - Move to the item at the beginning of the menu.",1);
  &print_nl("e - Move to the item at the end of the menu.",1);
  &print_nl("r - Refresh the screen.",1);
  if ($menu_shell_text ne "") {
    &print_nl("! = Enter command shell via \"$menu_shell_text\".",1);
  }
  &print_nl(" ",1);
  &addstr("[Press any key to continue]");
  &refresh();
  $ch = &getch();
  if ($ch eq "") { &menu_hangup_proc(); }
  &clear(); $xrow = $xcol = 0;
  &refresh();
}

sub print_nl {
  local($text,$skip) = @_;

  &addstr($text);
  if ($skip) { &nl($skip); }
  &refresh();
}

sub nl {
  local($skip) = @_;
  $xrow += $skip;
  $xcol = 0;
  if ($xrow > $main'LINES - 1) {
    &clear(); $xrow = 0; $xcol = 0;
    &refresh();
  }
  &move($xrow,$xcol);
}

sub defbell {
  eval q#
    sub bell { print "\007"; }
  #;
}

#**********
# MENU_TEMPLATE_SETEXIT
#
# Function:  Set alternative exit keys that may be used to exit a template
#
# Call format: &menu_template_setexit(@exit_key_array);
#			OR
#		&menu_template_setexit("exit_seq1","exit_seq2",...);
#
# Arguments:  exit_key_array - the keys to end menu_display_template on
#
# Returns:   Nothing
#*********
sub menu_template_setexit { @template_exitkeys = @_; }

#**********
# MENU_LOAD_TEMPLATE
#
# Function:  Load screen-input template from a file for later processing.
#
# Input:     Filename
#
# Returns:   0=Success, 1=Cannot open file
#**********
sub menu_load_template {
  local($filename) = @_;

  &menu_load_template_init_internal;
# Load the template
  open(TEMPLATE,$filename) || return(1);
  while(<TEMPLATE>) {
    chop;
    &menu_load_template_internal($_);
  }
  close(TEMPLATE);
  return(0);
}

#**********
# MENU_LOAD_TEMPLATE_ARRAY
#
# Function:  Load screen-input template from an array for later processing.
#
# Input:     Array, one element for each line in template
#
# Returns:   0=Success
#**********
sub menu_load_template_array {
  &menu_load_template_init_internal;
  for (@_) {
    &menu_load_template_internal($_);
  }
}

#**********
# MENU_LOAD_TEMPLATE_INIT_INTERNAL -  Common initialization routine for
# menu_load_template and menu_load_template_array.
#**********
sub menu_load_template_init_internal {
  $row = -1;
# Free up any old data
  $field = 0;
  @menu_template_line = ();
  @menu_template_row = @menu_template_col = ();
  @menu_template_len = @menu_template_type = ();
  @req_mark_row = @req_lmark_col = @req_rmark_col = ();

  &menu_overlay_clear(1);
}


#**********
# MENU_LOAD_TEMPLATE_INTERNAL
#
# Function:  Common routine for menu_load_template and menu_load_template_array.
#            Does the real work when loading a template
#
# Input:     One line of the template
#
# Returns:   Nothing
#**********
sub menu_load_template_internal {
  local($_) = @_;

  $row++;
  $menu_template_line[$row] = $_;
  next if !/_/ && !/\\/&& !/^/;;
  $line = $_;
  $menu_template_line[$row] =~ tr/_\\^/ /;
  $i = 0;
  $len = length($line);
  while ($i < $len) {
    while ((substr($line,$i,1) ne "_") && (substr($line,$i,1) ne "\\") &&
	     (substr($line,$i,1) ne "^") && ($i < $len)) { $i++; }
    last if ($i >= $len);
    $col = $i;
    $seek = substr($line,$i,1);
    while ((substr($line,$i,1) eq $seek) && ($i < $len)) { $i++; }
    $stop = $i;
    $field_len = $stop - $col;
    $menu_template_row[$field] = $row;
    $menu_template_col[$field] = $col;
    $menu_template_len[$field] = $field_len;
    if ($seek eq "\\") { $menu_template_type[$field] = 1; }	# Numeric
    elsif ($seek eq "^") { $menu_template_type[$field] = 2; }	# Noshow
    else { $menu_template_type[$field] = 0; }			# Alpha-num
    $field++;
  }
}

#**********
# MENU_OVERLAY_CLEAR
#
# Function:  Clear any template overlays
#
# Input:     Flag to clear "sticky" overlays (0=leave, 1=clear)
#
# Returns:   Nothing
#**********
sub menu_overlay_clear {
  local($clear_sticky) = @_;
  local($i);

# Clear current menu overlays
  for ($i = 0; $i <= $#menu_overlay_text; $i++) {
    next if ($menu_overlay_stick[$i] && !$clear_sticky);

    # Blank out any overlay on the screen (if within user exit routine)
    if ($template_exit_active) {
      $menu_overlay_text[$i] =~ tr/ / /c;	# Non-blanks to blanks
      &move($menu_overlay_row[$i],$menu_overlay_col[$i]);
      &addstr($menu_overlay_text[$i]);
    }

    # Reset this entry
    $menu_overlay_row[$i] = $menu_overlay_col[$i] = 0;
    $menu_overlay_rend[$i] = $menu_overlay_stick[$i] = 0;
    $menu_overlay_text[$i] = "";
  }
}

#**********
# MENU_OVERLAY_TEMPLATE
#
# Function:  Create overlayed text areas on a template screen
#
# Input:     - Row,col to start overlay on
#            - Overlay string (in sub-title,bottom-title format)
#            - Rendition flag (0=normal,1=standout)
#            - Sticky flag (0=always clear, 1=clear only with "clear all")
#
# Returns:   0=Success (w/loaded array), 1=No template loaded or invalid parms
#**********
sub menu_overlay_template {
  local($over_row,$over_col,$over_text,$over_rend,$over_stick) = @_;
  local($i) = $#menu_overlay_text;

# Check for template loaded
  if ($field <= 0) { return(1); }

# Validate position/string and load
  if (($over_row < 0) || ($over_col < 0)) { return(1); }
  if (($over_row < $main'LINES) && ($over_col < $main'COLS) && 
       ($over_text ne "")) {
    $i++;
    $menu_overlay_row[$i] = $over_row;
    $menu_overlay_col[$i] = $over_col;
    $menu_overlay_text[$i] = $over_text;
    $menu_overlay_rend[$i] = $over_rend;
    $menu_overlay_stick[$i] = $over_stick;
    return(0);
  } else { return(1); }
}

#**********
# MENU_DISPLAY_TEMPLATE
#
# Function:  Allow input from loaded template
#
# Input:     - Pointer to array to load with data. Required
#            - Pointer to array containing defaults for all fields. Optional.
#            - Pointer to array containing protection status for all fields
#	       Optional.
#            - String containing the name of an exit routine
#            - Pointer to array containing "required field" values. Optional.
#
# Returns:   0=Success (w/loaded array), 1=No template loaded
#**********
sub menu_display_template {
  local(*menu_template_data,*field_defaults,*protected,
	$template_exit_rtn,*required) = @_;
  local($i,$j,$unprot_cnt,$noshow,$numeric,$str,$done,$direction,$last_field);
  local($req_field_cnt,$still_req_cnt,$do_refresh,$redraw_flag) = 0;
  local(@data_win_cpos) = ();

# Check for template loaded
  if ($field <= 0) { return(1); }

# Do some initial stuff
  @menu_template_data = ();
  if ($template_exit_rtn ne "") {
    $template_exit_rtn = "main'$template_exit_rtn";
  }

# Display the screen
  &display_template_internal(0);

# Allow data entry if there is one unprotected field
  if ($unprot_cnt) {

    # Setup additional exit keys (in addition to "Return")
    $exit_seq[0] = "\t";		# Tab
    $exit_seq[1] = $kd;			# Cursor-down
    $exit_seq[2] = $ansi_kd;		# Ansi cursor-down
    $exit_seq[3] = $ku;			# Cursor-up
    $exit_seq[4] = $ansi_ku;		# Ansi cursor-up
    $exit_seq[5] = $redraw_screen;	# Redraw screen
    $exit_seq[6] = $next_field;         # Emacs-style editing
    $exit_seq[7] = $prev_field;         # Emacs-style editing
    &menu_setexit(@exit_seq,@template_exitkeys);

    # Input data from all data windows until "Return exit"
    $exit = $exit_seq[0]; # To tab over first protected fields
    $done = 0;
    $direction = 1;
    $i = 0;
    while ($protected[$i]) { $i++; } # Skip forward to first unprot field

    while (1) {
      $last_field = $i;
      if ($menu_template_type[$i] == 1) { $noshow = 0; $numeric = 1; }
      elsif ($menu_template_type[$i] == 2) { $noshow = 1; $numeric = 0; }
      else { $noshow = 0; $numeric = 0; }

      # Get data from current window (handling redraw as necessary)
      do {
	$menu_template_data[$i] = &menu_getstr(0,0,"",0,
				$menu_template_data[$i],
				$menu_template_len[$i],
				$noshow,$numeric,
				$data_win[$i],
				$data_win_cpos[$i]);
	$data_win_cpos[$i] = $last_window_cpos;
	$exit = &menu_getexit();

	if ($exit eq $exit_seq[5]) {
	  &display_template_internal(1);
	  $redraw_flag = 1;
	  $i = $last_field;
	} else { $redraw_flag = 0; }
      } until (!$redraw_flag);

      # Move to next unprotected field in the desired direction
      if (($exit eq $exit_seq[0]) || ($exit eq $exit_seq[1]) ||
          ($exit eq $exit_seq[2]) || ($exit eq $exit_seq[6])) {
	$direction = 1;
      }
      elsif (($exit eq $exit_seq[3]) || ($exit eq $exit_seq[4])
             || ($exit eq $exit_seq[7]) ) {
	$direction = -1;
      }
      else { $done = 1; $direction = 0;}

      if (!$done) {
	$j = $i;		# Remember where we were
	while (1) {
	  $i += $direction;
	  if ($i >= $field) { $i = 0; }
	  elsif ($i < 0) { $i = $field-1; }
	  last if (!$protected[$i]);	# Found a usable field
	  if ($i == $j) {	# Argh! They protected everything on us!
	    $done = 1;			# We are done
	    $template_exit_rtn = "";	# No more exits allowed
	  }
	}
      }

      # Compute count of fields required but not filled in.
      $still_req_cnt = 0;
      if ($req_field_cnt) {
	$req_first = -1;
	for ($j = 0; $j < $field; $j++) {
	  if ($required[$j] && !$protected[$j] &&
	      ($menu_template_data[$j] eq "")) {
	    $still_req_cnt++;
	    if ($req_first < 0) { $req_first = $j; }
	  }
	}
      }

      $do_refresh = 0;	# Assume we don't need a refresh.

      # Call any exit routine.  Return value indicates continue-field/return
      if ($template_exit_rtn ne "") {
	$template_exit_active = 1;
	$i = &$template_exit_rtn($direction,$last_field,$i,$still_req_cnt);
	$template_exit_active = 0;
	if ($i < 0) { $done = $i; }
	else {
	  $done = 0;
	  if (($i < 0) || ($i >= $field)) { $i = 0; } # Validate next field
	}
	# Place any overlays on the screen
	if ($#menu_overlay_text >= 0) {
	  for ($j = 0; $j <= $#menu_overlay_text; $j++) {
	    &move($menu_overlay_row[$j],$menu_overlay_col[$j]);
	    if ($menu_overlay_rend[$j]) { &standout(); }
	    &addstr($menu_overlay_text[$j]);
	    if ($menu_overlay_rend[$j]) { &standend(); }
	  }
	  $do_refresh = 1;
	}
      }

      # Place required field markers on the screen
      if ($req_field_cnt && ($direction == 0)) {
	$do_refresh = &mark_req_fields(1);
      }

      if ($do_refresh) { &refresh(); }

      # If done, make sure all required fields supplied, then finish up.
      if ($done) {
	if ($still_req_cnt > 0 && $done != -2) {
	  $i = $req_first;
	  $done = 0;
	} else {
	  last;
	}
      }
    }

# No unprotected fields - display screen until keypress
  } else {
    &move(0,0);	# Put cursor in upper-left corner
    &refresh();
    &getch();
  }

# Delete data windows for all fields
  for ($i = 0; $i < $field; $i++) { &delwin($data_win[$i]); }

# Reset exit sequences
  @exit_seq = ();
  &menu_setexit(@exit_seq);

# Clear screen
  &clear();
  &refresh();
  return(0);
}

#**********
# DISPLAY_TEMPLATE_INTERNAL
#
# Function:  Clear screen and draw template, data windows, overlays, and
#	     required field markers.  Functions for both initial screen
#	     and refresh.
#
# Input:     Boolean flag (0=First time, 1=refresh)
#
# Returns:   Nothing (screen is updated).
#**********
sub display_template_internal {
  local($refresh) = @_;
  local($i,$j);

# Clear the screen and paint the template
  &clear();
  for ($i = 0; $i <= $#menu_template_line; $i++) {
    &move($i,0);
    &addstr($menu_template_line[$i]);
  }

# Prepare data windows for all fields
  if (!$refresh) { $unprot_cnt = 0; }
  for ($i = 0; $i < $field; $i++) {

    # Create a data window
    if (!$refresh) {
      $data_win[$i] = &subwin($window,1,$menu_template_len[$i],
			$menu_template_row[$i],$menu_template_col[$i]);
    }

    if ($refresh) {
      &wmove($data_win[$i],0,0);
      if ($menu_template_type[$i] == 2) { # Hidden data - hide the default
	$str = "";
	for ($j = 0; $j < length($menu_template_data[$i]); $j++) { $str .= "*"; }
	&waddstr($data_win[$i],$str);
      } else {
	&waddstr($data_win[$i],$menu_template_data[$i]);
      }
      &wrefresh($data_win[$i]);
    } else {
      # Place default in field (if there is one)
      if ($field_defaults[$i] ne "") {
	if (length($field_defaults[$i]) > $menu_template_len[$i]) {
	  $field_defaults[$i] = substr($field_defaults[$i],0,
				     $menu_template_len[$i]);
	}
	$menu_template_data[$i] = $field_defaults[$i];
	&wmove($data_win[$i],0,0);
	if ($menu_template_type[$i] == 2) { # Hidden data - hide the default
	  $str = "";
	  for ($j = 0; $j < length($field_defaults[$i]); $j++) { $str .= "*"; }
	  &waddstr($data_win[$i],$str);
	} else {
	  &waddstr($data_win[$i],$field_defaults[$i]);
	}
	&wrefresh($data_win[$i]);
      } else { $menu_template_data[$i] = ""; }
    }

    if (!$protected[$i] && !$refresh) { $unprot_cnt++; }

    # Figure out required field marker positions.
    if ($required[$i]) {
      if (!$refresh) { $req_field_cnt++; }
      if ($req_lmark_set ne "") {
	$j = $menu_template_col[$i]-$required[$i]-length($req_lmark_set)+1;
	if ($j < 0) { $j = 0; }
	$req_mark_row[$i] = $menu_template_row[$i];
	$req_lmark_col[$i] = $j;
      }
      if ($req_rmark_set ne "") {
	$j = $menu_template_col[$i]+$menu_template_len[$i]+$required[$i]-1;
	if ($j > $main'COLS - length($req_rmark_set)) {
	  $j = $main'COLS - length($req_rmark_set);
	}
	$req_mark_row[$i] = $menu_template_row[$i];
	$req_rmark_col[$i] = $j;
      }
    }
  }

# Place any overlays on the screen
  if ($#menu_overlay_text >= 0) {
    for ($i = 0; $i <= $#menu_overlay_text; $i++) {
      &move($menu_overlay_row[$i],$menu_overlay_col[$i]);
      if ($menu_overlay_rend[$i]) { &standout(); }
      &addstr($menu_overlay_text[$i]);
      if ($menu_overlay_rend[$i]) { &standend(); }
    }
  }

# Place required field markers on the screen
  &mark_req_fields($refresh);

  &refresh();
}

#**********
# MARK_REQ_FIELDS
#
# Function:  Mark required fields on the screen.
#
# Input:     Boolean flag (0=First time, 1=refresh)
#
# Returns:   0=Nothing to do (no required fields to be marked), 1=Did some
#**********
sub mark_req_fields {
  local($refresh_flag) = @_;
  local($j,$rc) = 0;

  for ($j = 0; $j < $field; $j++) {
    if ($required[$j]) {
      if ($req_lmark_set ne "") {
	&move($req_mark_row[$j],$req_lmark_col[$j]);
	if (($menu_template_data[$j] eq "") || !$refresh_flag) {
	  if ($req_lmark_attr) { &standout(); }
	  &addstr($req_lmark_set);
	  if ($req_lmark_attr) { &standend(); }
	} else {
	  &addstr($req_lmark_clear);
	}
	$rc = 1;
      }
      if ($req_rmark_set ne "") {
	&move($req_mark_row[$j],$req_rmark_col[$j]);
	if (($menu_template_data[$j] eq "") || !$refresh_flag) {
	  if ($req_rmark_attr) { &standout(); }
	  &addstr($req_rmark_set);
	  if ($req_rmark_attr) { &standend(); }
	} else {
	  &addstr($req_rmark_clear);
	}
	$rc = 1;
      }
    }
  }
  return($rc);
}

my %color_pair_index;
my @color_pairs;

sub perlmenu_init_pair {
    my($n, $fg, $bg) = @_;
    $color_pairs[$n] = [$fg, $bg];
    $color_pair_index{"$fg.$bg"} = $n;
    init_pair($n, $fg, $bg);
}

sub create_color_pair {
    my($fg, $bg) = @_;

    my $n = $color_pair_index{"$fg.$bg"};
    if (defined $n) {
        return $n;
    }

    my $i = 1;
    while ($i < 256) {
        next if $color_pairs[$i];
        perlmenu_init_pair($i, $fg, $bg);
        return $i;
    }
    continue {
        ++$i;
    }

    die 'Unable to create color pair';
}

package perlmenu::label;

use strict;
use integer;
use warnings;

use overload '""' => sub { my $self = shift; return $self->{text} };

1;
