#!/usr/local/bin/perl
#****************************************************************************
# create_menu.pl
#
# Function: Convert Perl5-style "perlmenu.pm" to Perl4-style "menu.pl"
#
# Version:  4.0
#
# Date:     February 1997
#
# Author:   Steven L. Kunz
#           Networked Applications
#           Iowa State University Computation Center
#           Ames, IA  50011
#****************************************************************************

  open(PM,"perlmenu.pm") || die "Cannot find perlmenu.pm here!\n";
  open(PL,">menu.pl") || die "Cannot open menu.pl here for output!\n";

  print "\nConverting perlmenu.pm to menu.pl ...";

  $flushing = 0;
  $found_name = 0;

  while (<PM>) {
    if (/^#%PERL5ONLY%/o) { $flushing = !$flushing; }
    elsif (!$flushing) {
      if (/^sub menu_/o) {	# Could be an external entry point ...
	($rtn_name,$rest) = /^sub (\S+) (.*)/o;
	if ($external_entry{$rtn_name}) { $_ = "sub main'$rtn_name $rest\n"; } 
      } elsif (!$found_name) {	# A small attempt at effeciency
	if (/^# perlmenu.pm/) {
	  $found_name = 1;
	  $_ = "# menu.pl -- Perl Menu Support Facility\n";
	}
      }

      # curseperl entry points are in "main"
      s/\&clear/\&main\'clear/;
      s/\&subwin/\&main\'subwin/;
      s/\&wmove/\&main\'wmove/;
      s/\&addstr/\&main\'addstr/;
      s/\&endwin/\&main\'endwin/;
      s/\&wgetch/\&main\'wgetch/;
      s/\&initscr/\&main\'initscr/;
      s/\&noecho/\&main\'noecho/;
      s/\&wdelch/\&main\'wdelch/;
      s/\&getch/\&main\'getch/;
      s/\&wclrtoeol/\&main\'wclrtoeol/;
      s/\&standend/\&main\'standend/;
      s/\&tigetstr/\&main\'tigetstr/;
      s/\&winsch/\&main\'winsch/;
      s/\&waddstr/\&main\'waddstr/;
      s/\&clrtoeol/\&main\'clrtoeol/;
      s/\&getcap/\&main\'getcap/;
      s/\&cbreak/\&main\'cbreak/;
      s/\&delwin/\&main\'delwin/;
      s/\&nocbreak/\&main\'nocbreak/;
      s/\&wrefresh/\&main\'wrefresh/;
      s/\&echo/\&main\'echo/;
      s/\&refresh/\&main\'refresh/;
      s/\&standout/\&main\'standout/;
      s/\&move/\&main\'move/;
      s/sub perlmenu::getcap/sub main::getcap/;

      # Certain perlmenu entry points are in "main", too
      if (!/^#/o) { # (Don't change the comments)
	s/\&menu_getstr/\&main\'menu_getstr/;
	s/\&menu_overlay_clear/\&main\'menu_overlay_clear/;
	s/\&menu_setexit/\&main\'menu_setexit/;
	s/\&menu_getexit/\&main\'menu_getexit/;
      }

      print PL $_;
    } elsif (/\@EXPORT/) {	# List of external entry points follows ...
      $collect = "";
      while (<PM>) {		# Collect all names
	last if !/menu_/;
	chop($_);
        $collect .= $_;
      }
      # Split names into hashed array for later.
      for (split(/\s+/, $collect)) { $external_entry{$_} = 1; }
    }
  }

  close(PM);
  close(PL);

  print "\nAll done.\n\n";
  print "You now have a \"menu.pl\" to use with Perl4/curseperl.\n";
  print "It can also be used for existing applications under Perl5,\n";
  print "however it would be BEST for covert them to \'use perlmenu;\'\n";
  print "rather than \'require \"menu.pl\";\'.\n";
  print "Save your \"perlmenu.pm\" module for whenever you convert to Perl5+Curses.\n\n";
