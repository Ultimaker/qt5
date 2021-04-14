PATCHES
================
The patches directory contains required patches that must be applied to qtBase and qtDeclarative submodules during a build.
These patches are Ultimaker specific and compatible with QT 5.12.3.
See patches.txt in this top level directory for specific details of what each patch fixes and/or it's origin.

HOW TO BUILD qt-ultimaker
================

Perform a clean checkout of the qt5 ultimaker repository.
cd into the directory and checkout the branch you wish to build from.
Build sysroot first by executing, as sudo, otherwise it will be unable to create dirs:
```
sudo ./build_sysroot.sh
```

If you wish to build a debug build, then skip to that section now, otherwise follow the steps below to build a non-debug build.

Once that is completed you may build the default qt-ultimaker package by executing: 
```
sudo ./build_for_ultimaker.sh
```

This must also be executed as sudo in order to access the mounted folders that sysroot has made.

The build will take a long time to execute.

HOW TO BUILD qt-ultimaker with DEBUG symbols enabled
================

Assuming you have built sysroot, the next step is to build qt-ultimaker. Below is how you can enable debug symbols.

By default we build the qt-ultimaker package without debug symbols enabled. However during development, it can be useful to enable them and use them in conjunction with gdb to find out what  is going wrong in Qt.
In the qt5 branch, edit the file build.sh to include the flag '-debug' in the list of configure items, e.g:
```
"${SRC_DIR}/configure" \
        -platform linux-g++-64 \
        -device ultimaker-linux-imx6-g++ \
        -device-option CROSS_COMPILE="${CROSS_COMPILE}" \
        -sysroot "${SYSROOT}" \
        -extprefix "${TARGET_DIR}/qt" \by
        -confirm-license \
        -opensource \
        -no-use-gold-linker \
        -accessibility \
        -debug \
        ...
```
Now run the build with:
```
sudo ./build_for_ultimaker.sh
```

This will significantly increase the size of the produced qt-ultimaker package (~350 Mb or more) so in order to install this, the main printer partition must be increased to just over 3 Gb.
Branches containing this change for the R1 and R2 jedi-system-update packages are located here:
R1: https://github.com/Ultimaker/jedi-system-update/tree/r1_double_rootfs_partition
R2: https://github.com/Ultimaker/jedi-system-update/tree/r2_double_rootfs_partition

Simply install this firmware on your printer and you will be able to install debug versions of qt-ultimaker with a few extra steps.
Install qt-ultimaker package with debug symbols enabled on the printer

Copy the qt-ultimaker package to a usb key and plug it into the printer - having it stored on a USB key will save wasting space on the printer.
Uninstall the previous qt-ultimaker package and reboot to free up as much space as possible:
```
dpkg --purge --force-all qt-ultimaker
reboot
```

After rebooting, install the debug qt-ultimaker package from the usb, this will take a few minutes as the package is large. Afterwards reboot:
```
dpkg -i /media/usb0/<qt-ultimaker-debian-package>
reboot
```

The debug package is now installed.

Running gdb with a qt-ultimaker package with debug symbols enabled
================

On the printer install both gdb and python3.7-dbg. You may also create a symlink to /usr/bin/python3
```
apt update
apt install python3.7-dbg
apt install gdb
ln -s /usr/bin/python3 /usr/bin/python
```

Find the process id of the running okuda service, we will need this to attach the gdb too:
```
ps aux | grep oku*
ultimak+ 1735 17.2 5.8 181136 60156 ? Ssl 16:49 0:07 /usr/bin/python3 /usr/share/okuda/okuda_app.py
root 6106 0.0 0.0 2116 532 pts/0 S+ 16:50 0:00 grep oku*
```

In the example above, user ultimaker is running okuda with a PID of 1735. You may now attach gdb to this okuda service
```
gdb python 1735
```

gdb will read all symbols, this can take a few minutes.  Please wait until you see (gdb) appear on the console. At this point you may type 'c' (for continue) and hit return. The gdb will follow the process and when you encounter an error it will halt the process and present you with (gdb) in the console again. At this point you can execute:
```
thread apply all bt
```

This will show the backtrace for all threads associated with the okuda process and is useful debugging information. Save the output on screen to a text file.

To continue the process, type 'c' and hit enter. To detach gdb from the okuda process, type 'quit' and type 'y'
