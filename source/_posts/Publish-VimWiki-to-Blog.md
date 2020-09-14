---
title: Publish VimWiki to Blog
cwd: ~/Projects/blog
date: 2020-09-02 14:00:15
tags: [Programming, Perl, VimWiki]
---
### What is VimWiki?

I use [VimWiki](https://github.com/vimwiki/vimwiki) as my personal wiki and note taking tool. Sometimes what I write in my wiki I want to publish  to my [blog](/~timemachine3030). This script aims to do that.

## Requirements

In essence this is just a copy from my `~/vimwiki` folder into my `~/Projects/blogs/source/_posts/` folder. Hexo (my site generator) wants some meta data added to the top of the file, so I'll need to have that included. I'll most likely be in vim, editing the wiki, when I decide to publish it so I can create a vim command to initialize the copy, but I don't want to write the script in vimscript; that would be too much reliance on vim and I want to be able to publish any markdown file.

 - Copy first parameter to `~/Projects/blogs/source/_posts/` make configurable if it's easy.
 - Add the hexo meta data to the top of the file. There is a template for this in `~/Projects/blogs/scafolds/`
 - Add `tags` as switches to the command, as `--tags "Programming, Markdown"` or as `--tag Programming --tag Markdown`

The fun thing about writing requirements for even the smallest of scripts is you get a first shot of thinking about your interface. While looking up the location of hexo's scaffolds folder and thought to my self "I can just use hexo to create the file and then append the vimwiki file to the end". Will that work? Probably, it couples this tool tightly to hexo, but so does using hexo's template format. Uncoupling from the template format is more configuration than I want to do for this small "get some automation in place script".

## I guess bash?

Originally I wanted to write this program in JavaScript and run it in with npm. There are loads of command line argument parsers for node.js and file manipulation is easy. The requirements tell me that two commands should do what I want...

Never mind... The hexo command line tools don't have the ability to add tags from the invocation of `hexo new page ...`. 

I could use `sed` to parse the header and write the tags in. I'm not great at `sed` and I would be just copy something off stack overflow to solve the issue. I don't want to do that.

I could write a hexo plugin but that's whole different rabbit hole.

## Maybe Perl?

A fun maxim is: "if bash scripts can get 75% of the way there Perl can finish it"[^1]. You can quote a bash command in backticks (or `px()`) and Perl will run it and return the result.  This is not a bad choice considering the short comings I describe in the previous chapter. I don't want to "tool up" for this project so I hope the version of per that ships with MacOS is good enough, `v5.30.0`[^2] 

## The Script

(#save publish_from_vimwiki.pl) Process command line arguments
```perl
use strict;
use warnings;
use File::Basename;
use Getopt::Long qw(GetOptions);
 
my ($path) = shift;
die "Filename Required" unless $path;

my @tags;
my $taglist = "";
GetOptions("tag:s@" => \@tags, "tags:s" => \$taglist);
$taglist = $taglist . ', ' if $taglist;
$taglist = $taglist . join(', ', @tags);

my ($title,$dir,$ext) = fileparse($path, qr/\.[^.]*/);
```

This allows commands like `publish_from_vimwiki.pl ~/vimwiki/somefile.md --tags "SomeTag, Two, Three"` the `GetOpt()` call will look for individual tags in `--tag` or/and a comma separated list of tags in `--tags`. Everything ends up in the `$tagslist` scalar.

(#save publish_from_vimwiki.pl) Create blog post
```perl
my @result = qx(hexo --cwd="~/Projects/blog" new post "$title");
my $blogfile = $result[-1];
$blogfile =~ s/INFO  Created:\s+([^\r\n]+)[\r\n]/$1/;
$blogfile = glob($blogfile);

rename($blogfile, $blogfile.'.bak') or die $!;
```

Here we crate the new post, calling `hexo new post` directly. Then munch the results of the hexo command to get the name of the file it created. We make a back of the new post; need to remove that after we are done:

(#save publish_from_vimwiki.pl|cleanup)
```perl
unlink $blogfile.'.bak';
```

Now we can copy the backup file back into the blog post file modifying the tags along the way.

(#save publish_from_vimwiki.pl) Write the header of the blog w/ tags
```perl
open(BLOGIN, '<'.$blogfile.'.bak') or die $!;
open(OUT, '>'.$blogfile) or die $!;

while(my $line = <BLOGIN>) {
    $line =~ s/tags:/tags: [$taglist]/g;
    print OUT $line;
}
close(BLOGIN);
```

Finally we are ready to append with VimWiki file contents to the blog post.

(#save publish_from_vimwiki.pl)
```perl
open WIKIIN, '<', $path or die $!;

while (my $line = <WIKIIN>) {
    print OUT $line;
}

close(WIKIIN);
close(OUT);
```

[^1]: This is never true.
[^2]: It is fine.


