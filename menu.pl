#****************************************************************************
# menu.pl -- Perl Menu Support Facility 
#
# Version: 3.3
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
#
# Notes:   Perl4 - Requires "curseperl"
#                  (distributed with perl 4.36 in the usub directory)
#          Perl5 - Requires "Curses" extension
#                  (ftp://ftp.ncsu.edu/pub/math/wsetzer)
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
# Copyright (C) 1992-96  Iowa State University Computation Center
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

# Preferences (set by "menu_pref")
$curses_application = 0;	# Application will do initscr, endwin
$center_menus = 0;		# Center menus
$gopher_like = 0;		# More gopher-like arrow keys
$disable_quit = 0;		# Disable "Quit" hot-key
$quit_prompt = "";		# Override Quit prompt
$quit_default = "y";		# Quit default response

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
$first_line = $last_line = $items_per_screen = $arrow_line = 0;
 
@menu_exitkeys = ();	# Exit-key strings
$menu_lastexit = "";	# Exit-key string that caused the last exit
$show_mail = "";
$max_item_len = 0;	# Length of longest selection text
$xpos = 0;		# Leftmost column of menu (for centering)

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

# PERL5 ONLY -- Uncomment these statements if you DON'T have "getcap()"
#               OR if the demo doesn't appear to work (there's a bug in
#               some getcap()'s).
#
#  This is for perl5.000
#
#if ($] == 5.000)
#{
#require Term::Cap;                     # Get Tgetent package
#$Term::Cap::ospeed = 9600;             # Suppress "nospeed" warning
#Term::Cap::Tgetent();                  # Define entry
#*main::getcap = sub { $Term::Cap::TC{shift} };  # Define local subroutine
#}
#
#  This is for perl5.001
#
#if ($] >= 5.001)
#{
#package Perl5::Menu_PL::Compat;        # Don't pollute menu.pl namespace
#require Term::Cap;                     # Get Tgetent package
#$term = Tgetent Term::Cap { OSPEED => 9600 };  # Define entry
#sub main::getcap { $term->{"_" . shift()} };  # Define local subroutine
#}

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
sub main'menu_curses_application {
  ($window) = @_;
  $curses_application = 1;

# Sanity check.  If no window, get one.
  if (!$window) { $window = &main'initscr(); }

  $window;
}

#**********
#  MENU_PREFS
#
#  Function:	Establish general default preferences for menu style.
#
#  Call format:	&menu_pref(center_menus,gopher_like);
#
#  Arguments:	- Boolean flag (0=left justified menus, 1=centered menus)
#		- Boolean flag (0=normal, 1=more gopher-like)
#		- Boolean flag (0=allow quit, 1=disable quit)
#		- String with default "Quit" prompt
#		- String with "Quit" default response character
#
#  Returns:	Nothing
#**********
sub main'menu_prefs {
  ($center_menus,$gopher_like,$disable_quit,$quit_prompt,$quit_default) = @_;

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
sub main'menu_template_prefs {
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
sub main'menu_shell_command { ($menu_shell_text) = @_; }

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
sub main'menu_quit_routine { $menu_exit_routine = "main'@_"; }

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
sub main'menu_help_routine {
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
sub main'menu_init {
  ($menu_numbered,$menu_top_title,$menu_is_top_one,$sub_titles,$bot_titles,
   $item_help) = @_;
  local($i,$justify);

# Perform initscr if not a curses application
  if (!$curses_application && !$window) { $window = &main'initscr(); }

# Load "magic sequence" array based on terminal type
  if (!$did_initterm) {		# Get terminal info (if we don't have it).
    &defbell() unless defined &bell;

# Uncomment if you have "getcap"
    $ku = &main'getcap('ku');	# Cursor-up
    $kd = &main'getcap('kd');	# Cursor-down
    $kr = &main'getcap('kr');	# Cursor-right
    $kl = &main'getcap('kl');	# Cursor-left
    $cr = &main'getcap('cr');	# Carriage-return
    $nl = &main'getcap('nl');	# New-line

# Uncomment if you have tigetstr (Solaris) instead of "getcap"
#    $ku = &main'tigetstr('kcuu1');	# Cursor-up
#    $kd = &main'tigetstr('dcud1');	# Cursor-down
#    $kr = &main'tigetstr('kcuf1');	# Cursor-right
#    $kl = &main'tigetstr('kcub1');	# Cursor-left 
#    $cr = &main'tigetstr('cr');	# Carriage-return
#    $nl = &main'tigetstr('nl');	# New-line

# Uncomment if you have terminfo (and tput) instead of "getcap"
#    $ku = `tput kcuu1`;         # Cursor-up
#    $kd = `tput kcud1`;         # Cursor-down
#    $kr = `tput kcuf1`;         # Cursor-right
#    $kl = `tput kcub1`;         # Cursor-left
#    $cr = `tput kent`;          # Carriage-return
#    $nl = `tput nel`;           # New-line

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
  $items_per_screen = $last_line - $first_line + 1;
  $arrow_line = $first_line;    # Arrow on top item by default

# Process item help routine.
  $menu_item_help_routine = "";
  if ($item_help) { $menu_item_help_routine = "main'$item_help"; }
  
# Enable "top menu" functions if first menu is a top menu.
  if (($menu_is_first_one) && ($menu_is_top_one)) { $menu_top_activated = 1; }
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
sub main'menu_paint_file {
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
  $items_per_screen = $last_line - $first_line + 1;
  $arrow_line = $first_line;    # Arrow on top item by default

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
sub main'menu_setexit { @menu_exitkeys = @_; }

#********** 
#  MENU_GETEXIT
#
#  Function:  Returns the key last used to exit menu_getstr
#
#**********
sub main'menu_getexit { return($menu_lastexit); }

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

    if (length($temp_title[$i]) >= $main'COLS) {
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
sub main'menu_item {
  local($item_text,$item_sel,$item_set) = @_;

# Sanity check
  if ($items_per_screen <= 0) { return(0); }
  if (!$item_text) { return($menu_index); }
  if (!$item_set) { $item_set = 0; }

# Adjust max length value (for centering menu)
  if (length($item_text) > $max_item_len) { $max_item_len = length($item_text); }

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
sub main'menu_display {
  ($menu_prompt,$arrow_spec,$menu_top_item) = @_;
  local($ret);

# Check for no "menu_item" calls.
  $total_items = $#menu_sel_text + 1;
  if ($total_items <= 0) {
    &main'nocbreak();		# ALWAYS turn off "cbreak" mode
    &main'echo();		# ALWAYS turn on "echo"
    return("%EMPTY%");
  }

  &main'clear(); $xrow = $xcol = 0;
  $last_menu_top_item = -1;	# Force drawing of menu items
  $ret=&menu_display_internal(0,$menu_prompt,$arrow_spec,$menu_top_item);
  if ($#_ > 0) { $_[1] = $arrow_spec; }
  if ($#_ > 1) { $_[2] = $menu_top_item; }
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
sub main'menu_display_radio {
  ($menu_prompt,$current,$done_text) = @_;
  ($last_arrow,$last_top) = 0;

# Check for no "menu_item" calls.
  $total_items = $#menu_sel_text + 1;
  if ($total_items <= 0) {
    &main'nocbreak();		# ALWAYS turn off "cbreak" mode
    &main'echo();		# ALWAYS turn on "echo"
    return("%EMPTY%");
  }

  &main'clear(); $xrow = $xcol = 0;
  $last_menu_top_item = -1;	# Force drawing of menu items

# Insert our top selection item (and adjust max length value)
  if ($done_text eq "") { $done_text = "(Accept this setting)"; }
  $_ = length($done_text);
  if ($_ > $max_item_len) { $max_item_len = $_; }
  unshift(@menu_sel_text,$done_text);
  unshift(@menu_sel_action,"%DONE%");
  $menu_index++;

  while (1) {
    $ret = &menu_display_internal(1,$menu_prompt,$last_arrow,$last_top,
				  $current);
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
sub main'menu_display_mult {
  ($menu_prompt,$done_text) = @_;
  local($last_arrow,$last_top,$i) = 0;
  local($ret);

# Check for no "menu_item" calls.
  $total_items = $#menu_sel_text + 1;
  if ($total_items <= 0) {
    &main'nocbreak();		# ALWAYS turn off "cbreak" mode
    &main'echo();		# ALWAYS turn on "echo"
    return("%EMPTY%");
  }

  &main'clear(); $xrow = $xcol = 0;
  $last_menu_top_item = -1;	# Force drawing of menu items

# Insert our top selection item (and adjust max length value)
  if ($done_text eq "") { $done_text = "(Done with selections)"; }
  $_ = length($done_text);
  if ($_ > $max_item_len) { $max_item_len = $_; }
  unshift(@menu_sel_text,$done_text);
  unshift(@menu_sel_action,"%DONE%");
  unshift(@selected_action,0);
  $menu_index++;

# Loop, allowing toggle of selections, until done.
  while (1) {
    $ret = &menu_display_internal(2,$menu_prompt,$last_arrow,$last_top,0);
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
sub main'menu_getstr {
  local($row,$col,$prompt,$cleanup,$default,$maxlen,$noshow,$dtype,$win,$cpos)
	= @_;
  local($prompt_col,$left_col,$action,$string,$i,$overstrike);
  local ($stars);

  if (!$win) { $win = $window; } # Use main window by default

# Set cbreak, noecho.
  &main'cbreak();
  &main'noecho();

# Make sure the default is not longer than the maximum lengths
  if (($maxlen > 0) && (length($default) > $maxlen)) {
    $default = substr($default,0,$maxlen);
  }
  
# Clear our area. Place prompt and any default on the screen
  &main'wmove($win,$row,$col);
  &main'wclrtoeol($win);
  if ($prompt ne "") { &main'waddstr($win,$prompt); }
  if ($default ne "") {
    if ($noshow) { 
      for ($i = 0; $i < length($default); $i++) { &main'waddstr($win,"*"); }
    } else { &main'waddstr($win,$default); }
  }

# Position cursor for data input
  $prompt_col = $col;
  $left_col = $prompt_col + length($prompt);
  if (!$cpos) { $col = $left_col + length($default); }
  else { $col = $cpos - 1; }
  &main'wmove($win,$row,$col);
  &main'wrefresh($win);

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
	&main'wmove($win,$row,$col);
      }
    }
    elsif (($action eq $kl) || ($action eq $ansi_kl)
	   || ($action eq $prev_char) ) {		# Left-arrow
      if ($i-1 < 0) { &bell(); }
      else {
	$col--; $i--;
	&main'wmove($win,$row,$col);
      }
    }
    elsif (($action eq "\177") || ($action eq "\010")) {	# Delete/BS
      if ($i-1 < 0) { &bell(); }
      else {
	$col--; $i--;
	&main'wmove($win,$row,$col);
	&main'wdelch($win);
	$string = substr($string,0,$i).substr($string,$i+1);
      }
    }
    elsif ($action eq $delete_right) {				# Delete right
      if ($i < length($string)) {
	&main'wdelch($win);
	$string = substr($string,0,$i).substr($string,$i+1);
      }
      else { &bell(); }
    }
    elsif (($action eq $cr) || ($action eq $nl) || 
	   ($action eq "\n")) {					# Terminate
      $last_window_cpos = $col + 1;	# Save current column (not offset)
      if ($cleanup) {
	&main'wmove($win,$row,$prompt_col);	# Clear our stuff
	&main'wclrtoeol($win);
	&main'wrefresh($win);
      }
      &main'nocbreak();		# ALWAYS turn off "cbreak" mode
      &main'echo();		# ALWAYS turn on "echo"
      return($string);
    }
    elsif (($action eq $ku) || ($action eq $ansi_ku) ||
           ($action eq $next_field) || ( $action eq $prev_field ) ||
	   ($action eq $kd) || ($action eq $ansi_kd)) {
      ; # Ignore
    } 
    elsif ($action eq $begin_of_line) {		# Go to begin-of-line
      $col = $prompt_col + length($prompt); $i=0;
      &main'wmove($win,$row,$col);
    }
    elsif ($action eq $end_of_line) {		# Go to end-of-line
      $col = $prompt_col + length($prompt) + length($string);
      $i   = length($string);
      &main'wmove($win,$row,$col);
    }
    elsif ($action eq $kill_line) {		# Delete to end-of-line
      if ($i != length($string)) { # Not at end of line
	&main'wclrtoeol($win);
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
	    &main'wmove($win,$row,$col);
	    &main'wdelch($win);
	    # Yank single-character kill_buffer
	    &main'winsch($win,ord($kill_buffer));
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
	    &main'waddstr($win,$stars."\0");
	    # Draw rest of string
	    $stars = '*' x length(substr($string,$i));
            &main'waddstr($win,$stars."\0");
	  }
	  else {
            # Draw yanked text
	    &main'waddstr($win,$kill_buffer."\0");
	    # Draw rest of string
	    &main'waddstr($win,substr($string,$i)."\0");
          }
	  $string = substr($string,0,$i) . $kill_buffer . substr($string,$i);
	  $col += length($kill_buffer);
	  $i   += length($kill_buffer);
	  &main'wmove($win,$row,$col);
       }
     }
    }
    else { # Any other character
      if ($overstrike) {	# Delete only char on single-char field
	&main'wmove($win,$row,$col);
	&main'wdelch($win);
	$string = "";
      }
      if ($left_col + length($string) + 1 > $maxcol) { &bell(); }
      else {
	if (($dtype == 1) && (index("0123456789",$action) < 0)) { &bell(); }
	else {
	  &main'wmove($win,$row,$col);	# Insert the character on the screen
	  if ($noshow) { &main'winsch($win,ord("*")); }
	  else { &main'winsch($win,ord($action)); }
	  $string = substr($string,0,$i).$action.substr($string,$i);
	  if (!$overstrike) {
	    $col++; $i++;
	    &main'wmove($win,$row,$col);
	  }
	}
      }
    }
    &main'wrefresh($win);
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
#		- Line number offset for the arrow (defaults to zero).
#		- Index of top item on screen (defaults to zero).
#		- Current selection (radio only).
#
#  Returns:     Selected action string (from second param on &menu_item)
#		%UP%    -- "u"|"U" pressed (or "t"|"T" and looking for top)
#               %EMPTY% -- Nothing in menu to display
#               %DONE%  -- Done with selections (radio and mult only)
#**********
sub menu_display_internal {
  ($menu_type,$menu_prompt,$arrow_spec,$menu_top_item,$radio_sel) = @_;
  local($i,$search,$low_sel);

# If looking for top menu, return with "%UP%".
  if ($finding_top) {
    if ($menu_is_top_one) { $finding_top = 0; } 
    else { return("%UP%"); }
  }

# Check for no "menu_item" calls.
  $total_items = $#menu_sel_text + 1;
  if ($total_items <= 0) {
    &main'nocbreak();		# ALWAYS turn off "cbreak" mode
    &main'echo();		# ALWAYS turn on "echo"
    return("%EMPTY%");
  }

  &main'cbreak();		# cbreak mode (each character available)
  &main'noecho();		# Menus are always "noecho"

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
  $arrow_line = $arrow_spec + $first_line;
  if ($menu_top_item + 1 > $total_items) { $menu_top_item = $total_items - 1; }
  if ($arrow_line < $first_line) { $arrow_line = $first_line; }
  if ($arrow_line > $last_line) { $arrow_line = $last_line; }

# Compute leftmost column (for left-justified or centered menus)
  $xpos = 0; # Assume left-justified menu (no centering)
  if ($center_menus) {
    if ($menu_numbered) { $xpos += 8; } # Adjust for "-> nnn) "
    if (($menu_type == 1) || ($menu_type == 2)) {
      if ($max_item_len > length($menu_sel_text[0])) {
	$xpos += 4; # Adjust for selection box "[X] "
      }
    }
    $xpos = int($main'COLS/2) - int(($xpos+$max_item_len)/2);
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
    if ($gopher_like) {
      if (($action eq $kr) || ($action eq $ansi_kr)) { $action = "\n"; }
      if (($action eq $kl) || ($action eq $ansi_kl)) { $action = "u"; }
    }

# Perform action based on keystroke(s) received
    $move_amt = 0;
    if ($action ne "") {
      $last_arrow_line = $arrow_line;
      if (($action eq $kd) || ($action eq $ansi_kd) ||		# Down-arrow
          ($action eq $next_field) ||
	  ($action eq $kr) || ($action eq $ansi_kr)) {		# Right-arrow
        $number = 0;
        if ($arrow_line < $max_sel_line) { $arrow_line++; }
        else {
	  if ($gopher_like) {
	    $move_amt = $items_per_screen;
	    $arrow_line = $first_line;
	  } else {
	    if ($arrow_line == $last_line) { $move_amt = 1; }
	  }
	}
      }
      elsif (($action eq $ku) || ($action eq $ansi_ku) ||	# Up-arrow
             ($action eq $prev_field) ||
	     ($action eq $kl) || ($action eq $ansi_kl)) {	# Left-arrow
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
	  } else { $move_amt = -1; }
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
	$number = 0;
      }
      elsif (($action eq "e") || ($action eq "E")) {		# End
	if (! $menu_single_page) {
	  $menu_top_item = $menu_index - $items_per_screen;
	}
	$arrow_line = $last_line;
	$number = 0;
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
	  $search = &main'menu_getstr($last_line+1,0,"Search string: ",1);
	  &main'cbreak();		# menu_getstr turned this off
	  &main'noecho();		# menu_getstr turned this on
	  if ($search) {		# Toggle selections
	    $search =~ tr/A-Z/a-z/;
	    $i = 1;  
	    while ($i < $menu_index) {
	      if ($selected_action[$i] >= 0) {
	        $low_sel = $menu_sel_text[$i];
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
	  &main'clear();
	  &menu_top_bot();
	  $last_menu_top_item = -1;
	  &menu_page();
      }
      elsif (($action eq "\177") || ($action eq "\010")) {	# Delete/BS num-reset
	  $number = 0;
	  $arrow_line = $first_line;
	  &menu_page();
      }
      elsif ((($action eq "Q")||($action eq "q")) && (!$disable_quit)) { # Quit
	&main'clear(); $xrow = $xcol = 0;
	&main'move(0,0);
	if ($quit_prompt eq "") { $ch = "Do you really want to quit?"; }
	else { $ch = $quit_prompt; }
	$ch .= " $quit_default";
	&main'addstr($ch);
	&main'move(0,length($ch) - 1);
	&main'refresh();
	$ch = &main'getch();
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
	&main'clear(); $xrow = $xcol = 0;
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
        if (($menu_top_activated) && (! $menu_is_top_one)) {
	  $finding_top = 1;
	  return("%UP%");
	}
      }
      elsif (($action eq "h") || ($action eq "H") ||		# Help
	     ($action eq "?")) {
	if (($action eq "?") && ($menu_item_help_routine ne "")) {
	  if ($number) { $item = $number - 1; }
	  else { $item = $menu_top_item + $arrow_line - $first_line; }
	  if (($item < $menu_top_item) || ($item > $menu_bot_item)) { 
	    &bell();
	    $number = 0;
	  }
	  else {
	    &$menu_item_help_routine($menu_sel_text[$item],$menu_sel_action[$item]);
	    &main'clear(); &main'refresh();
	  }
	} else {
	  &$menu_generic_help_routine();	# Show generic help page
	  &main'clear(); $xrow = $xcol = 0;
	  &main'refresh(); 
	}
	&menu_top_bot();	# Clear and re-display the current page
	$last_menu_top_item = -1;
	&menu_page();
      }
      elsif ($action eq "!") {					# Shell escape
	if ($menu_shell_text ne "") {
	  &main'clear(); $xrow = $xcol = 0;	# Clear screen
	  &main'refresh();
	  &main'nocbreak();	# ALWAYS turn off "cbreak" mode
	  &main'echo();		# ALWAYS turn on "echo"
	  $xrow = $xcol = 0;
	  &print_nl("Entering command shell via \"$menu_shell_text\".",1);
	  &print_nl("Return here via shell exit (normally Control-D).",1);
	  &main'refresh();
	  &main'endwin();
	  system($menu_shell_text);
	  &main'cbreak();	# cbreak mode (each character available)
	  &main'noecho();	# Menus are always "noecho"
	  &main'clear(); $xrow = $xcol = 0;	# Clear screen
	  &menu_top_bot();	# Re-display the current page
	  $last_menu_top_item = -1;
	  &menu_page();
	}
      }
      elsif (($action eq $cr) || ($action eq $nl) || 
	     ($action eq "\n")) {				# RETURN
	if ($number) { $item = $number - 1; }
	else { $item = $menu_top_item + $arrow_line - $first_line; }
	if (($item < $menu_top_item) || ($item > $menu_bot_item)) {
	  &bell();
	  $number = 0;
	}
	else {
          if ($#_ > 1) { $_[2] = $arrow_line - $first_line; }
          if ($#_ > 2) { $_[3] = $menu_top_item; }
	  return($menu_sel_action[$item]);
	}
      }
      else {
	$digit_val = index("0123456789",$action);		# Number
	if ($digit_val >= 0) {
	  $number = $number * 10 + $digit_val;
	  if ($number >= $menu_top_item + 1) { 
	    if ($number <= $menu_bot_item + 1) {
	      $arrow_line = $number - $menu_top_item + $first_line - 1;
	    } else {
	      &bell();
	      $number = 0;
	      $arrow_line = $first_line;
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

# Erase the last selection arrow
      if ($menu_numbered) {
	&main'move($last_arrow_line,$xpos);
	&main'addstr("  ");
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
    $ch = &main'wgetch($cwin);
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
  &main'move(0,$menu_top_title_col);
  if ($menu_top_title_attr == 0) { &main'standout(); }
  &main'addstr($menu_top_title);
  if ($menu_top_title_attr == 0) { &main'standend(); }

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
      &main'move($i+1,$menu_sub_title_col[$i]);
      if ($menu_sub_title_attr[$i] == 0) { &main'standout(); }
      &main'addstr($menu_sub_title[$i]);
      if ($menu_sub_title_attr[$i] == 0) { &main'standend(); }
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
      &main'move($j+$i,$menu_bot_title_col[$i]);
      if ($menu_bot_title_attr[$i] == 0) { &main'standout(); }
      &main'addstr($menu_bot_title[$i]);
      if ($menu_bot_title_attr[$i] == 0) { &main'standend(); }
    }
  }

  $items_per_screen = $last_line - $first_line + 1;
  &main'move($main'LINES - 1,7);
  &main'addstr($menu_prompt);
}

#**********
#  MENU_PAGE -- Display one page of menu selection items.
#**********
sub menu_page {
  local($i) = 0;
  local($curr_line,$line);
  local($refresh_items) = 0;

# Check for top item change (scrolling/paging of menu text).
  if ($menu_top_item != $last_menu_top_item) {
    $last_menu_top_item = $menu_top_item;
    $refresh_items = 1;
  }

# Refresh all items on screen
  if ($refresh_items) {
    # Update percentage on bottom line
    &main'move($main'LINES-1,0);
    &main'standout();
    if ($menu_single_page) { &main'addstr("(All) "); }
    else { &main'addstr(sprintf("\(%3d%%\)",$percent)); }
    &main'standend();
 
    # Display current page of menu
    $item = $menu_top_item;
    $menu_bot_item = $menu_top_item;
    $curr_line = $first_line;
    $max_sel_line = $first_line;

    while ($curr_line <= $last_line) {
      &main'move($curr_line,$xpos);
      &main'clrtoeol();
      $line = "";
      if ($item < $total_items) {
	$sel_num = $item + 1;
	if ($menu_numbered) { $line .= &menu_add_number($sel_num); }
	if ($menu_type) {
	  if ($sel_num != 1) {
	    if ($menu_type == 1) {
	      if ($menu_sel_action[$item] eq $radio_sel) { $line .= "[X] "; }
	      else { $line .= "[ ] "; }
	    } else { # menu_type is 2
	      if ($selected_action[$item] > 0) { $line .= "[X] "; }
	      elsif ($selected_action[$item] < 0) { $line .= "[-] "; }
	      else { $line .= "[ ] "; }
	    }
	  }
	}
	$line .= $menu_sel_text[$item];
	if (length($line) > $main'COLS - 1) { # Truncate lines that would wrap
	  $line = substr($line,0,$main'COLS - 1);
	}
	&main'addstr($line);
	$max_sel_line = $curr_line;
      }
      $item++;
      $curr_line++;
    }
    $menu_bot_item = $item - 1;
  } 
# Refresh only selection tags on radio/multi-select menus
  elsif ($menu_type) {
    $item = $menu_top_item;
    $curr_line = $first_line;
    $i = $xpos + 1;
    if ($menu_numbered) { $i += 8; }
    while ($curr_line <= $last_line) {
      if ($item < $total_items) {
	if ($item) {
	  &main'move($curr_line,$i);
	  if ($menu_type == 1) {
	    if ($menu_sel_action[$item] eq $radio_sel) { &main'addstr("X"); }
	    else { &main'addstr(" "); }
	  } else { # menu_type is 2
	    if ($selected_action[$item] > 0) { &main'addstr("X"); }
	    elsif ($selected_action[$item] < 0) { &main'addstr("-"); }
	    else { &main'addstr(" "); }
	  }
	}
      }
      $item++;
      $curr_line++;
    }
  }
 
# Position the selection arrow on the screen (if numbered menu)
  if ($arrow_line < $first_line) { $arrow_line = $first_line; }
  if ($arrow_line > $max_sel_line) { $arrow_line = $max_sel_line; }
  &main'move($arrow_line,$xpos);
  if ($menu_numbered) { &main'addstr("->"); }

# Write out current menu page
  &main'refresh();
}

#**********
# MENU_ADD_NUMBER -- Format selection number.
#**********
sub menu_add_number {
  local($sel_num) = @_;
  local($sel_str) = "  ";

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
  &main'nocbreak();
  &main'echo(); 
  &main'clear();  $xrow = $xcol = 0;
  &main'refresh(); 
  if (!$curses_application) { &main'endwin(); }
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
  &main'clear(); $xrow = $xcol = 0;
  &print_nl("--------------------------------",1);
  &print_nl("Menu Help (PerlMenu version 3.3)",1);
  &print_nl("--------------------------------",2);
  if ($menu_type == 1) {
    &print_nl("- Use up/down arrows to place \"->\" in front of your selection.",1);
    &print_nl("- Press Return (or Enter) to chose that selection.",1);
    &print_nl("- Select the first item when ready to continue.",2);
  }
  elsif ($menu_type == 2) {
    &print_nl("- Use up/down arrows to place \"->\" in front of your selection.",1);
    &print_nl("- Press Return (or Enter) to toggle the selection on/off.",1);
    &print_nl("- Select the first item when ready to continue.",2);
  } else {
    &print_nl("- Use up/down arrows to place \"->\" in front of your selection.",1);
    &print_nl("- Press Return (or Enter) when ready to continue.",2);
  }
  &print_nl("Available action-keys:",1);
  &print_nl("h - Show this help screen.",1);
  if ($menu_item_help_routine ne "") {
    &print_nl("? - Show help on the item with the \"->\" in front.",1);
  }
  if (!$disable_quit) {
    &print_nl("q - Quit entirely.",1);
  }
  &print_nl("u - Return to the previous menu or function.",1);
  if (($menu_top_activated) && (! $menu_is_top_one)) {
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
  &main'addstr("[Press any key to continue]");
  &main'refresh();
  $ch = &main'getch();
  if ($ch eq "") { &menu_hangup_proc(); }
  &main'clear(); $xrow = $xcol = 0;
  &main'refresh();
}

sub print_nl {
  local($text,$skip) = @_;

  &main'addstr($text);
  if ($skip) { &nl($skip); }
  &main'refresh();
}

sub nl {
  local($skip) = @_;
  $xrow += $skip;
  $xcol = 0;
  if ($xrow > $main'LINES - 1) {
    &main'clear(); $xrow = 0; $xcol = 0;
    &main'refresh();
  }
  &main'move($xrow,$xcol);
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
sub main'menu_template_setexit { @template_exitkeys = @_; }

#**********
# MENU_LOAD_TEMPLATE
#
# Function:  Load screen-input template from a file for later processing.
#
# Input:     Filename
#
# Returns:   0=Success, 1=Cannot open file
#**********
sub main'menu_load_template {
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
sub main'menu_load_template_array {
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

  &main'menu_overlay_clear(1);
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
sub main'menu_overlay_clear {
  local($clear_sticky) = @_;
  local($i);

# Clear current menu overlays
  for ($i = 0; $i <= $#menu_overlay_text; $i++) {
    next if (($menu_overlay_stick[$i]) && (!$clear_sticky));

    # Blank out any overlay on the screen (if within user exit routine)
    if ($template_exit_active) {
      $menu_overlay_text[$i] =~ tr/ / /c;	# Non-blanks to blanks
      &main'move($menu_overlay_row[$i],$menu_overlay_col[$i]);
      &main'addstr($menu_overlay_text[$i]);
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
sub main'menu_overlay_template {
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
sub main'menu_display_template {
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
    &main'menu_setexit(@exit_seq,@template_exitkeys);

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
	$menu_template_data[$i] = &main'menu_getstr(0,0,"",0,
				$menu_template_data[$i],
				$menu_template_len[$i],
				$noshow,$numeric,
				$data_win[$i],
				$data_win_cpos[$i]);
	$data_win_cpos[$i] = $last_window_cpos;
	$exit = &main'menu_getexit();

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
	  if (($required[$j]) && (!$protected[$j]) &&
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
	    &main'move($menu_overlay_row[$j],$menu_overlay_col[$j]);
	    if ($menu_overlay_rend[$j]) { &main'standout(); }
	    &main'addstr($menu_overlay_text[$j]);
	    if ($menu_overlay_rend[$j]) { &main'standend(); }
	  }
	  $do_refresh = 1;
	}
      }

      # Place required field markers on the screen
      if (($req_field_cnt) && ($direction == 0)) {
	$do_refresh = &mark_req_fields(1);
      }

      if ($do_refresh) { &main'refresh(); }

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
    &main'move(0,0);	# Put cursor in upper-left corner
    &main'refresh();
    &main'getch();
  }

# Delete data windows for all fields
  for ($i = 0; $i < $field; $i++) { &main'delwin($data_win[$i]); }

# Reset exit sequences
  @exit_seq = ();
  &main'menu_setexit(@exit_seq);

# Clear screen
  &main'clear();
  &main'refresh();
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
  &main'clear();
  for ($i = 0; $i <= $#menu_template_line; $i++) {
    &main'move($i,0);
    &main'addstr($menu_template_line[$i]);
  }

# Prepare data windows for all fields
  if (!$refresh) { $unprot_cnt = 0; }
  for ($i = 0; $i < $field; $i++) {

    # Create a data window
    if (!$refresh) {
      $data_win[$i] = &main'subwin($window,1,$menu_template_len[$i],
			$menu_template_row[$i],$menu_template_col[$i]);
    }

    if ($refresh) {
      &main'wmove($data_win[$i],0,0);
      if ($menu_template_type[$i] == 2) { # Hidden data - hide the default
	$str = "";
	for ($j = 0; $j < length($menu_template_data[$i]); $j++) { $str .= "*"; }
	&main'waddstr($data_win[$i],$str);
      } else {
	&main'waddstr($data_win[$i],$menu_template_data[$i]);
      }
      &main'wrefresh($data_win[$i]);
    } else {
      # Place default in field (if there is one)
      if ($field_defaults[$i] ne "") {
	if (length($field_defaults[$i]) > $menu_template_len[$i]) {
	  $field_defaults[$i] = substr($field_defaults[$i],0,
				     $menu_template_len[$i]);
	}
	$menu_template_data[$i] = $field_defaults[$i];
	&main'wmove($data_win[$i],0,0);
	if ($menu_template_type[$i] == 2) { # Hidden data - hide the default
	  $str = "";
	  for ($j = 0; $j < length($field_defaults[$i]); $j++) { $str .= "*"; }
	  &main'waddstr($data_win[$i],$str);
	} else {
	  &main'waddstr($data_win[$i],$field_defaults[$i]);
	}
	&main'wrefresh($data_win[$i]);
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
      &main'move($menu_overlay_row[$i],$menu_overlay_col[$i]);
      if ($menu_overlay_rend[$i]) { &main'standout(); }
      &main'addstr($menu_overlay_text[$i]);
      if ($menu_overlay_rend[$i]) { &main'standend(); }
    }
  }

# Place required field markers on the screen
  &mark_req_fields($refresh);

  &main'refresh();
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
	&main'move($req_mark_row[$j],$req_lmark_col[$j]);
	if (($menu_template_data[$j] eq "") || !$refresh_flag) {
	  if ($req_lmark_attr) { &main'standout(); }
	  &main'addstr($req_lmark_set);
	  if ($req_lmark_attr) { &main'standend(); }
	} else {
	  &main'addstr($req_lmark_clear);
	}
	$rc = 1;
      }
      if ($req_rmark_set ne "") {
	&main'move($req_mark_row[$j],$req_rmark_col[$j]);
	if (($menu_template_data[$j] eq "") || !$refresh_flag) {
	  if ($req_rmark_attr) { &main'standout(); }
	  &main'addstr($req_rmark_set);
	  if ($req_rmark_attr) { &main'standend(); }
	} else {
	  &main'addstr($req_rmark_clear);
	}
	$rc = 1;
      }
    }
  }
  return($rc);
}

1;
