# Copyright © 2016 SUSE LLC
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

# Summary: Patch SLE11* and SLE12* qcow2 images before migration (offline)
# Maintainer: Dumitru Gutu <dgutu@suse.de>

use base "consoletest";
use strict;
use testapi;
use utils;
use registration;

sub patching_sle() {

    set_var("VIDEOMODE",    'text');
    set_var('SCC_REGISTER', 'installation');

    select_console 'root-console';

    # stop packagekit service
    script_run "systemctl mask packagekit.service";
    script_run "systemctl stop packagekit.service";

    assert_script_run("zypper lr && zypper mr --disable --all");
    save_screenshot;
    yast_scc_registration();
    assert_script_run('zypper lr -d');
    minimal_patch_system(version_variable => 'HDDVERSION');

    if (sle_version_at_least('12-SP1', version_variable => 'HDDVERSION')) {
        assert_script_run('SUSEConnect -d');
        my $output = script_output 'SUSEConnect -s';
        die "System is still registered" unless $output =~ /Not Registered/;
        save_screenshot;
    }
    else {
        assert_script_run("zypper removeservice `zypper services --sort-by-name | awk {'print\$5'} | tail -1`");
        assert_script_run('rm /etc/zypp/credentials.d/* /etc/SUSEConnect');
        my $output = script_output 'SUSEConnect -s';
        die "System is still registered" unless $output =~ /Not Registered/;
        save_screenshot;
    }
    assert_script_run("zypper mr --enable --all");

    set_var("VIDEOMODE",    '');
    set_var('SCC_REGISTER', '');
}

sub run() {

    select_console 'root-console';
    type_string "chown $username /dev/$serialdev\n";
    # enable Y2DEBUG all time
    type_string "echo 'export Y2DEBUG=1' >> /etc/bash.bashrc.local\n";
    script_run "source /etc/bash.bashrc.local";
    patching_sle();
}

sub test_flags {
    return {milestone => 1, fatal => 1};
}

1;
