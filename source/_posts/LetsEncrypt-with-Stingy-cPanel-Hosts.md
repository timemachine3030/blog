---
title: LetsEncrypt with Stingy cPanel Hosts
date: 2024-10-01 20:49:56
tags:
---

## Part 1: An old enemy

I did the cheapest, most obnoxious thing ... I bought domain hosting from a Domain Name Registrar. Virtual Hosts, puke.

It was weakness, really. I have a side project that I'm working on and needed a brochure site to sell it (more on this in the coming weeks). I know HTML so I slung together some bootstrap nonsense and went domain name hunting. Found a good name too, some real *dot-com top-level stuff*. Needed some place to squat it and some static web hosting. My registrar had a deal, 12 months of hosting for a few extra bucks ... what is the worst that can happen? Well I'll tell you!

The VHost stood up very quickly. Then there was this big, grey button of doom and dread in the middle of the screen, "LAUNCH CPANEL." All caps. My stomach sank at the word: *cPanel*.

I use to work with cPanel on the daily back in the 1990s. I worked for a now defunct hosting company manning the racks. We had 20 co-lo racks with 8 to 10 servers per rack and about 40 or so dell PowerEdge desktop units free standing on gorilla racks behind my cubicle. All running Apache and cPanel.

That job was like painting an aircraft carrier. Took so long to update the os security patches on all the servers that as soon as you finished it was time to start over. Ansible and Chef[^1] where not realities, just crash carts[^2] and bash scripts.

I wore a headset attached to a wireless phone, *ring ring* "Network Ops, what's down?"

"You ran a perl script you found on usenet and now your server is wedged? That shouldn't happen...oh you ran it as root. OK, let me see if I can get it. Nope ssh isn't running anymore...I can plug into it, what is your security phrase? Of course you don't know it. Should be in an email you got when you signed up...oh the stuck server has your webmail on it? I can't unlock your rack without the security phrase...oh I see, yeah you can call my boss. I'm sure he remembers you. I'm sure he will answer your call at 10pm on a Friday." *click*

*ring ring* "Network Ops, what's down? Hello again...remember that security phrase?" Five years of the same battleship grey.

## Part 2: Least significant security

[Let's Encrypt](https://letsencrypt.org/) is a free SSL/TLS certificate issuing authority. Those certs are the ones that make the little lock show up in your web browser's location bar. These days, if you try to access a website that's doesn't have a valid cert you get an error about that the site you are visiting being *dangerous*. I guess that's true.

If you are taking credit card payments on a web site, Let's Encrypt shouldn't be your first option. By using their certificates you have to hold them harmless in the event their security is comprized and a bad actor sniffs your site's traffic and steal's your customer's identity.

> If you are collecting personal information on the internet alway make sure there is someone else to sue.

But I'm not making that kind of web site. So a free cert is all I'm going to pay for.

I googled...There is a [cPanel plugin](https://docs.cpanel.net/knowledge-base/third-party/the-lets-encrypt-plugin/) for fetching a cert from Let's Encrypt. Easy!

Oh wait I forgot to mention: my Domain Name Registrar, now Hosting Provider, also sells SSL certificates. Of course they didn't install the plugin to allow their customers to get a freebie. We're gonna have to do it the hard way.

## Part 3: Asshole deep in alligators

At its core, cPanel is a bunch of perl code that makes managing virtual host's a point an click adventure. It runs on top of the Apache web server and generates configuration files for [Apache](https://httpd.apache.org/), [PHP](https://www.php.net/), [MySQL](https://mariadb.org/), [Roundcube](https://www.php.net/), [cron](https://linux.die.net/man/5/crontab), [named(8)](https://linux.die.net/man/8/named) and [bind](https://linux.die.net/man/2/bind). There are also a bunch of installers for Wordpress, Joomla, phpBB, and that short of shovel-ware. We will get back to this...

Let's Encrypt has a command line application you can install, called *certbot*. It is a nice piece of kit. You tell certbot what domain you own and the web root on the server for that domain (`/var/www/` or there about). Then the certbot creates a file inside a known location on the public facing side or your domain and tells the Let's Encrypt system to look for it. So if you own `example.com`, certbot makes a file at `http://example.com/.well-known/acme-challenge`. There is a hash in that file that only certbot and Let's Encrypt know, and agree on. If the remote Let's Encrypt server sees the right hash at the url, then they know you own the domain. So they issue you the certificate.

Certbot then installs the cert on the server, restarts the httpd service, and finally registers a *cron* job to check back every few days to keep the cert up-to-date (they expire after 3 months).

Unfortunately, certbot wants to be installed and run as root. Which is fine, it is going to restart services on the host, it needs escalated privileges. But this is a shared host, I ain't got no root access. 

There are non-root ways to use the Let's Encrypt system. I could, for example, run certbot on my local desktop. It will tell me the secret code to upload to the website and then spit out the certificates for me to install by hand...Or I could create a `TXT` record in the DNS entries for the site install the cert by hand...every 3 months. I'm sure I'll never forget. No risk of a potential customer going to my site and seeing that *using this website will cause identity theft and your credit score will instantly go into the single digit range*.

I know how certbot orchestrates generating the TLS certifications, the protocol is called ACME. And I can get dangerous with cPanel. So I take a deep breath and dive in.

## Part 4: Hack and slash solutions

I need a non-root ACME client that runs in a language that I have available on the vhost. [There is a list of recommendations on the Let's Encrypt site](https://letsencrypt.org/docs/client-options/). I picked a php script called [acme-client.phar](https://letsencrypt.org/docs/client-options/) (*phar* is the PHp ARchive format). I used FTP (file transfer protocol) to ship the phar and a Yaml config to the server and ran it. How did I run it? 

I used cPanel's *crontab* editor to run it, of course. 

Cron let's you run scripts on a schedule. For example, *back up the database every morning at 1am*. You just need to know the command, and cPanel has a fancy interface to copy/paste and configure those commands to run.  

I created an entry in cron to run at *3 minutes after I made the entry* and then deleted it. So it was like I was logged into the console, only harder.


The entry looked like this:

```
33 * * * * /usr/local/bin/php -d display_errors=on $HOME/bin/acme-client.phar >> $HOME/logs/cert_renew.log
```

The vhost had php's configuration set to not show errors (known source of vulnerabilities) so I fixed that with, `-d display_errors=on`. Then I have the output logged to a file I can download and debug, or confirm that it worked.

Here is the Yaml config for acme-client.phar:

```yaml
storage: ~/ssl/
server: letsencrypt
email: me@exmaple.com
certificates:
    - rekey: true
        paths:
        ~/public_html:
                - exmaple.com
                - mail.exmaple.com
                - www.exmaple.com
                - cpanel.exmaple.com
                - webmail.exmaple.com
                - webdisk.exmaple.com
                - cpcontacts.exmaple.com
                - cpcalendars.exmaple.com
                - autodiscover.exmaple.com
```

Worked sweet! Now I have a bundle of SSL/TLS *pem* files that prove I own the domain. All I need to do now is *not* install them by hand!

## Part 5: I'll let myself in

There is another cPanel plugin that lets you configure your certificates. Basically some big text boxes in the browser for you copy/paste the bundle from your supplier. Not a big deal if you buy the cert from the hosting company because the ones you pay for usually don't expire for 1 to 3 years. 

If cPanel has a plugin for it there is an API for it. Cold truth. After all, it is just a trash heap of perl and php scripts. [This](https://api.docs.cpanel.net/openapi/cpanel/operation/install_ssl/) is true for the tools that install ssl certs. The command loads the certificate, makes an entry in the Apache config for your virtual host, and restarts the server. Just like certbot would have :)

Here is another script for you to run from cron that calls the cPanel command to install those ill-gotten certificates:

```php
<?php
print "Copying certificates to cPanel\n";
$storage = $_SERVER['HOME'] . "/ssl/certs/acme-v02.api.letsencrypt.org.directory/";
$url = "example.com";

$cert = file_get_contents($storage . $url . "/cert.pem");
$key = file_get_contents($storage . $url . "/key.pem");

if ($cert === false || $key === false) {
    print "Error reading certificate or key file\n";
    exit(1);
}

$cert = urlencode($cert);
$key = urlencode($key);
$response = `uapi --output=jsonpretty SSL install_ssl domain='$url' cert='$cert' key='$key'`;

print "Done\n\n $response\n";
```

The last detail is making a final cron job to renew the certificate once a month:

```bash
#!/usr/bin/env bash
  
export PATH='/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'

php -d display_errors=on $HOME/bin/acme-client.phar >> $HOME/logs/cert_renew.log

RC=$?

if [ $RC = 4 ] || [ $RC = 5 ]; then
  php -d display_errors=on $HOME/bin/install_certs.php >> $HOME/logs/cert_renew.log
fi
```

The lengths and determination I take to save $100... thanks for reading.

[^1]: Tools for automating and distributing tasks across clusters of servers. Ansible was released in 2012. Chef in 2009, well over a decade before my days running Yum commands in ssh terminals.

[^2]: A *Crash cart* is a piece of server room furniture. Usually a double decker table on wheels. On the top tier is a monitor, key board, and mouse for plugging into the a server and getting direct console access. Useful for when the machine is so broken it won't accept connections over the network. The second shelf if home to network cables, a spare battery for the wireless phone, a tool bag to dismantle the server, and 5 or more empty diet coke cans. **No food or drink in the server room!** 