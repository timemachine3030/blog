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
my @result = qx(hexo --cwd="~/Projects/blog" new post "$title");
my $blogfile = $result[-1];
$blogfile =~ s/INFO  Created:\s+([^\r\n]+)[\r\n]/$1/;
$blogfile = glob($blogfile); # expand ~

rename($blogfile, $blogfile.'.bak') or die $!;

open(BLOGIN, '<'.$blogfile.'.bak') or die $!;
open(OUT, '>'.$blogfile) or die $!;

## Copy the Contents of the backup to the blog post rewriting the tags inline
while(my $line = <BLOGIN>)
{
    $line =~ s/tags:/tags: [$taglist]/g;
    print OUT $line;
}
close(BLOGIN);

open WIKIIN, '<', $path or die $!;

## Copy the Contents of the Wiki file to the blog post
while (my $line = <WIKIIN>) {
    print OUT $line;
}

close(WIKIIN);
close(OUT);

unlink $blogfile.'.bak';

