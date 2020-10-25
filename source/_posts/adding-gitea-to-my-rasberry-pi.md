---
title: Adding Gitea To My Raspberry Pi
date: 2020-09-24 09:36:10
tags: 
 - git
 - Raspberry-Pi
---

## Background

I recently set up a Raspberry Pi to run pi-hole on my network. It works great.
The specific Pi I used is a Raspberry Pi 3 Model B. Running Pi-hole is not
resource intensive. To get get more out of the device, I'm going to add an
installation of [Gitea](https://gitea.io).


## Hardware

In addition to the Raspberry Pi, I'm plugging in a 4Tb external hard drive.
This will give my family a solid amount of network storage for backups (Time
Machine / Duplicity).

I have decided to use full disk encryption. I like the added security on
the device, but there are some drawbacks. Most importantly, the disk can not be
auto-mounted when the Pi boots. A user must supply the password to decrypt the
disk before it is mounted.

Alternatives to full disk encryption are available:

 - Both Time Machine and Duplicity can encrypt their backup folders
 - Git repos can be encrypted at rest with these projects
    - https://github.com/AGWA/git-crypt
    - https://github.com/spwhitton/git-remote-gcrypt



### Mounting the Hard Drive

`/dev/disks/` has helpful symlinks to help you locate your usb attached devices:

```
pi@pi-hole:/media $ ls -la /dev/disk/by-path/
total 0
drwxr-xr-x 2 root root 140 Sep 24 19:05 .
drwxr-xr-x 7 root root 140 Sep 22 22:52 ..
lrwxrwxrwx 1 root root  13 Sep 22 22:52 platform-3f202000.mmc -> ../../mmcblk0
lrwxrwxrwx 1 root root  15 Sep 22 22:52 platform-3f202000.mmc-part1 -> ../../mmcblk0p1
lrwxrwxrwx 1 root root  15 Sep 22 22:52 platform-3f202000.mmc-part2 -> ../../mmcblk0p2
lrwxrwxrwx 1 root root   9 Sep 24 19:05 platform-3f980000.usb-usb-0:1.5:1.0-scsi-0:0:0:0 -> ../../sda
lrwxrwxrwx 1 root root  10 Sep 24 19:05 platform-3f980000.usb-usb-0:1.5:1.0-scsi-0:0:0:0-part1 -> ../../sda1
```

The last file in the listing is my drive, `/dev/sda1`. I need to add the
`cryptsetup` package to unlock the hard drive before it is mounted.

```
$ sudo apt install cryptsetup
$ sudo cryptsetup open /dev/sda1 storage

$ sudo mkdir /media/storage
$ sudo chown -R pi:pi /media/storage
$ sudo mount /dev/mapper/storage /media/storage 
```

Note, to unmount the disk: `sudo umount /media/storage` only removes the mount
point, you also need to close the luks mapper: `sudo cryptsetup close storage` 

As described above, We can not use `fstab` to auto-mount this drive. Instead, I'll place a script
in my user's home directory to decrypt and mount the drive.

```
#!/bin/bash -e

cryptsetup open /dev/disk/by-uuid/f623a6e2-ea38-4f82-882a-c9823b53f0cf storage
mount /dev/mapper/storage /media/storage

echo "Done!"

```

Here I used another helper from `/dev/disk` to mount by the hard drive's UUID.
This ensures that if I add a second drive, in the future, I do not need worry
about which the kernel finds first and assigns to `sda1` or `sdb1`.


## Proxy Config

Pi-hole includes Lighttpd to serve it's web pages.  Conveniently, Lighttpd
includes `mod_proxy` to allow the web server to act as a reverse proxy. Gitea's
web server (written in Go, by-the-way) defaults to listening at port 3000. The
next step is to make a new configuration for forwarding requests by host name.

Pi-hole's http config is in the default Lighttpd location
`/etc/lighttpd/lighttpd.conf`. There is an include statement in the config that
reads files in `/etc/lighttpd/conf-enabled/`. The `conf-enabled` directory is
comprised of symlinks to `../conf-available`. 

Make a new file `/etc/lighttpd/conf-available/50-gitea.conf`:

```
server.modules += ( "mod_proxy" ) 
 
$HTTP["host"] == "vox.localnetwork" { 
    proxy.server = ( 
        "" => ( 
            ( "host" => "localhost", "port" => "3000" ) 
        )
    )
}
```

This configuration loads the proxy module, defines a new host name:
`vox.localnetwork`, and finally tells the server to redirect (proxy) requests
to `localhost:3000`.  

Create symlink, test the config changes, and restart Lighttpd:

```
$ sudo ln -s /etc/lighttpd/conf-available/50-gitea.conf /etc/lighttpd/conf-enabled/50-gitea.conf
$ sudo lighttpd -tt -f /etc/lighttpd/lighttpd.conf
$ sudo systemctl restart lighttpd
```

Checking in the browser, Pi-hole is still listening. While we are in the
pi-hole admin let's setup the DNS services in Pi-hole to bind the url to the
Raspberry Pi's static IP address.  Log into http://pi.hole and click `Local DNS Records`

![Local DNS Records](/~timemachine/images/pi-hole-config.png)

This setting will forward all requests on my LAN for url `vox.localnetwork`
[^1] to the Raspberry Pi.


## Gitea Install

Raspberry Pi 3 has an ARM7 processor. At the time of writing Gitea version
1.12.0 won't build correctly for the ARM7 target. That's okay as ARM7 is
backwards compatible to ARM6, so that is the download we will use.

We need a system user for all git related activity, also there are many
directories we need to create

```
sudo adduser --system --shell /bin/bash --gecos 'Git Version Control' --group --disabled-password --home /home/git git

mkdir -p /media/storage/gitea/{custom,data,log}
sudo chown -R git:git /media/storage/gitea/
sudo chmod -R 751 /media/storage/gitea/

mkdir /media/storage/gitea-repositories
sudo chown -R git:git /media/storage/gitea-repositories

sudo mkdir /etc/gitea
sudo chown root:git /etc/gitea/
sudo chmod 770 /etc/gitea/
```

You may notice the permissions on `/media/storage/gitea` are set to `751`. This
is because of an issue that I ran into (and I have run across with Apache
server as well) where the service can not create files in a directory that is not
executable by everyone.

The git user, that is running the service, has `rwx` permission on the directory
but if you do not add `o+x` there will be permission denied errors when you try
to start the service.  


### Gitea Database

Many of the online resources for installing Gitea on Raspberry Pi use
MySQL/MariaDB. I'm going to use SQLite3 to keep configuration simple.


### Downloading Binary

Check for the latest version at https://dl.gitea.io/gitea/ and replace the link below:

```
wget -O gitea.bin https://dl.gitea.io/gitea/1.12.4/gitea-1.12.4-linux-arm-6
sudo mv gitea.bin /usr/local/bin/gitea
```

### Test Startup

Test that the application will start from the command line before we create
a service.

```
sudo su git
GITEA_WORK_DIR=/media/storage/gitea /usr/local/bin/gitea web -c /etc/gitea/app.ini
```

This starts the service and we confirm that it listens on `0.0.0.0:3000`. If
your port is different you need to update the Lighttpd config to point to the
correct port.


### Create the service

I suggest copying the [example service
file](https://github.com/go-gitea/gitea/blob/master/contrib/systemd/gitea.service)
and search for the values: `WorkingDirectory` and `GITEA_WORK_DIR`.  Update
them to your working directory (`/media/storage/gitea` for this example). The
service configuration file is saved to: `/etc/systemd/system/gitea.service`

At this point you can stop and start the process with `sudo systemctl start gitea`
and `sudo systemctl stop itea`. I'm not going to `enable` the service
to start at boot. The encrypted hard disk will not be ready. Instead I will add
the `systemctl` command to my `mount_storage.sh` script.


### Initial Configuration

Point your browser to the server, http://vox.localnetwork for me.  This is the
initial configuration I chose. 

![Gitea Initial Config](/~timemachine/images/gitea-initial-config.png)

This configuration is saved to `/etc/gitea/app.ini`.

There are also options to allow emails (you supply the SMTP server, user, and
password) but I skipped those as I'm the only user, at this point, that can
connect to the host. It is easy to add these setup steps in the future if
needed.


### Register First User

The first user that registers becomes the admin of the site. That's convenient. 

Once signed in you can view your profile settings and add your public ssh key.
Finally, you are ready to create and clone your first repo.

## Review

I was able to run through these steps quickly (even while taking notes for this
blog). It was a delight to see how easy it has become to create mount points in
Linux over time. I remember, back in 1996, scratching my head as I read through
the man pages for fstab and mount, trying to sort out how to mount a second
disk to use as the /home on my desktop. That was Slackware v3.0 (I still have
the CD-ROM for that here somewhere), I looked up the kernel version:
1.2.13...Yikes!

My next plan is to install Samba on the Raspberry pi so the family can take
full advantage of the 4Tb I've connected to the network.


[^1]: https://timemachine.fandom.com/wiki/Vox
