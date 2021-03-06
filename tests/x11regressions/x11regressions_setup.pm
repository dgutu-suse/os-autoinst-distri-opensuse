# X11 regression tests
#
# Copyright © 2016 SUSE LLC
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

# Summary: Common setup for x11regression tests
# Maintainer: mitiao <mitiao@gmail.com>

use base "x11regressiontest";
use strict;
use testapi;

sub run() {
    #Switch to x11 console, if not selected, before trying to start xterm
    select_console('x11');

    x11_start_program("xterm");

    # grant user permission to access serial port until next reboot
    script_sudo "chown $username /dev/$serialdev";

    # get permanent user permission to access serial port even if reboot
    script_sudo "gpasswd -a $username \$(ls -l /dev/$serialdev | awk \"{print \\\$4}\")";

    # quit xterm
    type_string "exit\n";
}

# add milestone flag to save setup in lastgood vm snapshot
sub test_flags() {
    return {milestone => 1, fatal => 1};
}

1;
# vim: set sw=4 et:
