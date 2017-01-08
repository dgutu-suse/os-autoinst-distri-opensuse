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

sub patching_sle11() {

    my ($registration, $email, $regcode, $regcode_ha, $regcode_geo, $regopts) = @_;
    $email       = get_var("SCC_EMAIL");
    $regcode     = get_var("SCC_REGCODE");
    $regcode_ha  = get_var("SCC_REGCODE_HA");
    $regcode_geo = get_var("SCC_REGCODE_GEO");

    # block update process before registration
    script_run("gconftool-2 --set /apps/gnome-packagekit/frequency_get_updates --type=string never");

    if (get_var("SCC_REGCODE_GEO")) {
        $regopts = "-a regcode-sles=$regcode -a regcode-slehae=$regcode_ha -a regcode-slehaegeo=$regcode_geo";
    }
    elsif (get_var("SCC_REGCODE_HA")) {
        $regopts = "-a regcode-sles=$regcode -a regcode-slehae=$regcode_ha";
    }
    else {
        $regopts = "-a regcode-sles=$regcode";
    }
    $registration = script_output("suse_register -n -a email=$email $regopts", 90);

    die "Unable to register the system, please check logs" unless $registration =~ /Registration finished successfully/;
    save_screenshot;
    assert_script_run('zypper lr -d');

    #Patch the system
    minimal_patch_system();
    save_screenshot;
    my $reg_out = script_output("suse_register -E");
    die "Unable to erase system registration data" unless $reg_out =~ /Successfully erased local registration data/;
    save_screenshot;
    script_run("gconftool-2 --set /apps/gnome-packagekit/frequency_get_updates --type=string daily");
    assert_script_run('zypper lr -d');
}

sub patching_sle12() {

    select_console 'root-console';

    # stop packagekit service
    script_run "systemctl mask packagekit.service";
    script_run "systemctl stop packagekit.service";

    assert_script_run("zypper lr && zypper mr --disable --all");
    save_screenshot;
    yast_scc_registration;
    assert_script_run('zypper lr -d');
    minimal_patch_system;

    if (sle_version_at_least('12-SP1')) {
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
}

sub run() {

    select_console 'root-console';

    type_string "chown $username /dev/$serialdev\n";
    # enable Y2DEBUG all time
    type_string "echo 'export Y2DEBUG=1' >> /etc/bash.bashrc.local\n";
    script_run "source /etc/bash.bashrc.local";

    if (get_var('HDDVERSION', '') =~ 'SLES-11') {
        patching_sle11;
    }
    else {
        patching_sle12;
    }
}

sub test_flags {
    return {milestone => 1, fatal => 1};
}

1;
