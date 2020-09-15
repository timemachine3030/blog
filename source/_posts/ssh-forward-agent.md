---
title: Securing SSH Keys on Shared Hosts
date: 2020-09-14 14:36:30
tags:
    - Security
    - ssh
    - Tilde
---

First a warning:

> Don't put your ssh private keys on a shared host!

The issue is that you can't trust your fellow users on the shared host. You may have set the items in the `~/.ssh/` directory with `chmod 400` but that doesn't prevent root users from seeing them.

In this article we will discuss an alternative for using ssh keys to connect to git, or other servers, on a shared system.

## Background

I've recently started to develop some small software projects on [ctrl-c.club](http://ctrl-c.club). Ctrl-c is a shared server (tilde) with a few hundred other users. We have local mail, irc, and a bulletin board that we use to create a community of command-line aficionados. Since I'm developing software on this shared space I want to use version control. The server has `git` installed so I can easily send my software assets to [github](https://github.com) or [TildeGit](https://tildegit.org/).

On my localhost I have created an easy workflow for `pushing` changes to github using SSH. I have a public/private key pair in my local `.ssh` directory and [have shared my public key with github.com](https://docs.github.com/en/github/authenticating-to-github/connecting-to-github-with-ssh)

To replicate this on the shared server I would need to copy those keys to the `.ssh` directory (or create a new set of keys) on the server. This, however, is a bad security practice. I trust the server's admins not to steal my keys and modify my github account but you may not. Or more correctly I shouldn't *have to trust the admins*. Security should be the default of my workflow.

## Local Configuration

Here are the contents of my `.ssh` directory on my local work station:

```
pilot@morlock:~$ ls -l .ssh
total 20
-rw------- 1 pilot pilot  404 Sep 14 13:47 authorized_keys
-rw-rw-r-- 1 pilot pilot  302 Sep 14 13:41 config
-rwx------ 1 pilot pilot 1743 Sep 12 23:38 id_rsa
-rwx------ 1 pilot pilot  407 Sep 14 13:47 id_rsa.pub
-rw-r--r-- 1 pilot pilot 2212 Sep 14 17:24 known_hosts
```

`id_rsa` is my private key. `id_rsa.pub` is my public key, that has been shared with github.com, and is also used to log into Ctrl-c.club. `authorized_keys` is a list of public keys that can login to my local desktop (it contains the public key I use on my laptop). `known_hosts` are the public key finger prints that I trust (github.com, ctrl-c.club, and others).

Finally the `config` file has information on where and when to use my ssh keys:

```
Host ccc
    User timemachine
    ControlPath ~/.ssh/cm-%r@%h:%p
    ControlMaster auto
    ControlPersist 10m
    IdentityFile /home/pilot/.ssh/id_rsa
    Hostname ctrl-c.club

Host github.com
    User timemachine3030
    IdentityFile /home/pilot/.ssh/id_rsa
```

You can learn more about the configurations at my [blog post that about setting them up](/~timemachine/2020/09/09/First-Day-in-the-Tildesphere/). 

The `Control*` properties are for reusing an open ssh connection for new terminals and `scp` secure copies.

## Agent Forwarding

Installing OpenSSL in Linux or MacOS[^0] includes the `ssh-agent` utility to hold private keys used in public key authentication. When you *unlock* your private keys, using their password, ssh-agent stores the key contents as part of your login shell (or key chain on MacOS). It is a handy way to prevent you from needing to type the password for every authenticated request (similar to the function of `sudo` remembering your password for a while).

One of the bonuses of using ssh-agent is that you can tell OpenSSH to forward your unlocked keys along to other secure connections you create.

## Setup

This is the easy part. Under the `Host` heading in your `~/.ssh/config` file add `ForwardAgent yes`.

Here is my updated Ctrl-c.club config:

```
Host ccc
    User timemachine
    ControlPath ~/.ssh/cm-%r@%h:%p
    ControlMaster auto
    ControlPersist 10m
    IdentityFile /home/pilot/.ssh/id_rsa
    ForwardAgent yes
    Hostname ctrl-c.club
```

DONE!

## In Practice

Let's test that my local agent's private keys are accessible on the shared server by first logging in and then running [ssh to see if we get a connection](https://docs.github.com/en/enterprise/2.15/user/articles/testing-your-ssh-connection).

```
timemachine@copper:~$ ssh -T git@github.com
The authenticity of host 'github.com (140.82.114.4)' can't be established.
RSA key fingerprint is 16:27:ac:a5:76:28:2d:36:63:1b:56:4d:eb:df:a6:48.
Are you sure you want to continue connecting (yes/no)? 
```

**We are on a shared host so we don't want to blindly accept that public key!** Software could have been installed on the server to intercept our connections to Github and listen in. This is called a *man-in-the-middle-attack*. Let's discuss how to verify the public key fingerprint is authentic.

## Look Up Public Keys

Github publishes their [public key fingerprints](https://docs.github.com/en/github/authenticating-to-github/githubs-ssh-key-fingerprints) but not every server you connect to will have a web page to verify.

From our *localhost* (ie, not the remote server that is asking for confirmation) we can save the public key and then test it.

```
pilot@morlock:~$ ssh-keyscan github.com > github.pub
# github.com:22 SSH-2.0-babeld-42834f78
# github.com:22 SSH-2.0-babeld-42834f78
# github.com:22 SSH-2.0-babeld-42834f78
# github.com:22 SSH-2.0-babeld-42834f78
# github.com:22 SSH-2.0-babeld-42834f78
pilot@morlock:~$ ssh-keygen -l -f github.pub 
2048 SHA256:nThbg6kXUpJWGl7E1IGOCspRomTxdCARLviKw6E5SY8 github.com (RSA)
```

Passing `-l` to ssh-keygen asks to compute the fingerprint, `-f` says what file to use.

Oh no! OpenSSH on the Ctrl-c server shows the data as an md5 fingerprint and my localhost uses sha256. You can specify the hash algorithm with the `-E` option to ssh-keygen:

```
pilot@morlock:~$ ssh-keygen -E md5 -l -f github.pub 
2048 MD5:16:27:ac:a5:76:28:2d:36:63:1b:56:4d:eb:df:a6:48 github.com (RSA)
```

Good! Those are the same. We can trust the connection.

```
timemachine@copper:~$ ssh -T git@github.com
The authenticity of host 'github.com (140.82.114.4)' can't be established.
RSA key fingerprint is 16:27:ac:a5:76:28:2d:36:63:1b:56:4d:eb:df:a6:48.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added 'github.com,140.82.114.4' (RSA) to the list of known hosts.
Connection closed by 140.82.114.4
```

ssh will save the public key in `~/.ssh/known_hosts` and warn us if it changes in the future.


## Concussion

We have shown how to use ssh-agent forwarding to allow us to use our local private keys on remote servers only when we are logged in over a secure and trusted connection. Then we showed how to verify that we are only using those keys if we can verify that the security of the connection has not been snooped on.

For a man in the middle to compromise my connection from Ctrl-c.club to Github they would need to not only compromise the Crtl-c.club server, but also the Github.com website and my local network. We can feel pretty confident at this point that our connections are secure.

[^0]: After Lion.

