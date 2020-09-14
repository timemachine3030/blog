---
title: First Day in the Tildesphere
date: 2020-09-09 00:17:21
tags: 
    - Community
    - Tilde
---

# Welcome!

Ok. So you got logged in? Good, now let's get you set up.

## Forget your password

When you logged in for the first time you had to reset your password. Now let's make it so you never need it again by creating some public and private keys for you to log in with.

- Note: this step is for OS X and Linux users. If you are using Windows or OS/2 warp then you connected with puTTY and this was done for you. Skip down to the Tmux section.

In a terminal enter:

```bash
ssh-keygen
```

You will be prompted for a file to store your new keys. The default is in your home directory under the `.ssh` directory. That's  the  right folder but let's name it something different so we know what keys are which. I used `/Users/pilot/.ssh/ccc.id_rsa` (use your home directory). Skip the password or enter one if you want (skip it!).

```
$ ssh-keygen
Generating public/private rsa key pair.
Enter file in which to save the key (/Users/pilot/.ssh/id_rsa): /Users/pilot/.ssh/ccc.id_rsa
Enter passphrase (empty for no passphrase):
Enter same passphrase again:
Your identification has been saved in /Users/pilot/.ssh/ccc.id_rsa.
Your public key has been saved in /Users/pilot/.ssh/ccc.id_rsa.pub.
The key fingerprint is:
SHA256:MDv......dEfdcI2BZD7YIFhf0o77POQ8n4 pilot@timemachine.local
The key's randomart image is:
+---[RSA 3072]----+
| .+.     o.=+==  |
| ...+S.....+ =oo |
| .o o. o .o+..o  |
| ..o.+o +o++  .  |
| o +.o S+ o=o    |
| =   ..  . o.    |
| . =             |
| o +E            |
| .o..            |
+----[SHA256]-----+
```

Your output will look a bit different... enjoy the ascii art.

Next we will copy the public key to the server:

```sh
ssh-copy-id -i ~/.ssh/ccc.id_rsa USERNAME@ctrl-c.club
```

Enter your password for the server one last time. Now login again with

```sh
ssh -i ~/.ssh/ccc.id_rsa USERNAME@ctrl-c.club
```

Slick? The `-i` is for `identiy-file`. Here is the passage in the SSH docs about `-i`:

```
-i identity_file
             Selects a file from which the identity (private key) for public key authentica-
             tion is read.  The default is ~/.ssh/id_dsa, ~/.ssh/id_ecdsa, ~/.ssh/id_ed25519
             and ~/.ssh/id_rsa.  Identity files may also be specified on a per-host basis in
             the configuration file.  It is possible to have multiple -i options (and multi-
             ple identities specified in configuration files).  If no certificates have been
             explicitly specified by the CertificateFile directive, ssh will also try to load
             certificate information from the filename obtained by appending -cert.pub to
             identity filenames.
```

See that part in the middle there: `Identity files may also be specified on a per-host basis in the configuration file.` Let's do that next:

In your favorite editor open the file: `~/.ssh/config`. If you don't have a favorite editor just type one of the below:

- OS X: `open ~/.ssh/config` and it will open in TextEdit. TextEdit is the world's second worst editor (looking at you Notepad.exe).
- Linux: `nano ~/.ssh/config`

Add the lines below at the end of the file.

```
Host ccc
    User USERNAME
    IdentityFile /Users/pilot/.ssh/ccc.id_rsa
    Hostname ctrl-c.club
```

- Host ccc
    - The `ccc` is like a shortcut.
- User USERNAME
    - That's your ctrl-c.club username
- IdentityFile
    - The private key to sign your connection with
- Hostname ctrl-c.club
    - The host to connect to

Now save and close that up. To connect to the server you can now enter the command: 

```
ssh ccc
```

Welcome aboard.

## Tmux

One of the great holy wars of network geeks is Tmux vs Screen. Well, I'm here to convert you to the Tmux life style. Tmux stands for "terminal multiplexer". It does a few important things:

- It is persistent. It continues to run even when you detach and close your connection to the server. Next time you log in, re-attach to tmux and you are right where you left off. The session will stay there forever...unless the server is restarted.
- It multiplexes. You can create multiple sessions, windows, and panes running different programs.

In the shell:

```
tmux new -s chat
```

That will create a new `-s`ession called "chat". It will look like any old terminal only with a green glowing status bar at the bottom. Open the server's forum:

```
iris
```

If you are new to iris, type `h` to see the help. When you are done brushing up on the day's news. Let's learn our first tmux command. 

### Create a new window

All commands in tmux start with a prefix: the default is `Ctrl+b`. The key to create a new tmux window is `c` (for create). All together that is: `ctrl+b` lift your fingers then `c`. Boom, iris is gone; now we are at a new shell. Let's use this one for IRC. Run the command `irssi`. 

Type in the following:

```
/connect localhost
/join #ctrl-c
Hi timemachine!!! Thanks for the blog!
```

Connecting to localhost is the pro way to do it... Then you connect to Ctrl-C.club's channel...Finally say hello. I probably won't respond because that's just my tmux session idling.

### Issues? 

Before we continue. You should take the opportunity to tell me all the problems you found with this article up-to-this-point. I'm doing all this from memory; but you're smart, and have google, so you'll figure it out. But do let me know so I can update this for the next hacker.

### Switching Windows

What about the message board? Type `Ctrl+b 0` (zero) and you will switch to the iris window. `Ctrl-b 1` is IRC. If you look at the green status bar you can see `[chat] 0:ruby* 1:irssi-`.

- `[chat]` is the name of the session.
- `0:ruby*` is the iris forum window (the `*` means it is currently active)
- `1:irissi-` is the IRC client (the `-` means it's the last place you where)

To cycle through your windows: `Ctrl+b n` for "next" and `Ctrl+b p` for "previous"

### Persistence

Close your terminal ... don't log out, just close the app. Poof! Gonzo. Now open a new terminal, login in to copper (`ssh ccc`), and type: `tmux at -t chat` That will re-`at`tach you to the `-t`arget-session named `chat`.

### Learn more

To learn all about tmux open a new window (`Ctrl-b c`) and enter the command: `man tmux`  this will show you the manual page for the software. See if you can learn how to create a new pane and switch between them without using the mouse. (type `q` to quit man, `/` to search the document).



Have fun.



