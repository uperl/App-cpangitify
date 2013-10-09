package App::cpan2git;

use strict;
use warnings;
use autodie qw( :system );
use v5.10;
use BackPAN::Index;
use Getopt::Long qw( GetOptions );
use Pod::Usage qw( pod2usage );
use Path::Class qw( file dir );
use Git::Wrapper;
use File::Temp qw( tempdir );
use LWP::UserAgent;
use File::chdir;
use JSON qw( from_json );
use URI;
use PerlX::Maybe qw( maybe );

# ABSTRACT: Convert cpan distribution from BackPAN to a git repository
# VERSION

=head1 DESCRIPTION

This is the module for the L<cpan2git> script.  See L<cpan2git> for details.

=head1 SEE ALSO

L<cpan2git>

=cut

our $ua  = LWP::UserAgent->new;
our $opt_metacpan_url;

sub main
{
  my $class = shift;
  local @ARGV = @_;
  
  my $opt_backpan_index_url;
  my $opt_backpan_url;
  $opt_metacpan_url = "http://api.metacpan.org/";

  GetOptions(
    'backpan_index_url=s' => \$opt_backpan_index_url,
    'backpan_url=s'       => \$opt_backpan_url,
    'metacpan_url=s'      => \$opt_metacpan_url,
    'help|h'              => sub { pod2usage({ -verbose => 2}) },
    'version'             => sub {
      say 'cpan2git version ', ($App::cpan2git::VERSION // 'dev');
      exit 1;
    },
  ) || pod2usage(1);

  my $name = shift @ARGV;

  $name =~ s/::/-/g;

  pod2usage(1) unless $name;

  my $dest = dir()->absolute->subdir($name);

  if(-e $dest)
  {
    say "already exists: $dest";
    return 2;
  }

  say "creating/updating index...";
  my $bpi = BackPAN::Index->new(
    maybe backpan_index_url => $opt_backpan_index_url,
  );

  say "searching...";
  my @rel = eval { $bpi->dist($name)->releases->search(undef, { order_by => 'date' }) };

  if($@ || @rel == 0)
  {
    say "no releases found for $name";
    return 2;
  }

  say "mkdir $dest";
  $dest->mkpath(0,0700);

  my $git = Git::Wrapper->new($dest->stringify);

  $git->init;

  sub author($)
  {
    state $cache = {};
  
    my $cpanid = shift;
  
    unless(defined $cache->{$cpanid})
    {
      my $uri = URI->new($opt_metacpan_url . "v0/author/" . $cpanid);
      my $res = $ua->get($uri);
      unless($res->is_success)
      {
        say "error fetching $uri";
        say $res->status_line;
        return 2;
      }
      $cache->{$cpanid} = from_json($res->decoded_content)
    }
  
    sprintf "%s <%s>", $cache->{$cpanid}->{name}, $cache->{$cpanid}->{email}->[0];
  }

  foreach my $rel (@rel)
  {
    my $path    = $rel->path;
    my $version = $rel->version;
    my $date    = $rel->date;
    my $cpanid  = $rel->cpanid;
  
    say "$path [ $version ]";
  
    my $tmp = dir( tempdir( CLEANUP => 1 ) );
  
    local $CWD = $tmp->stringify;
  
    my $uri = URI->new(join('/', $opt_backpan_url, $path));
    say "fetch ...";
    my $res = $ua->get($uri);
    unless($res->is_success)
    {
      say "error fetching $uri";
      say $res->status_line;
      return 2;
    }
  
    do {
      open my $fh, '>', "archive";
      print $fh $res->decoded_content;
      close $fh;
    };
  
    say "unpack...";
    system 'tar', 'xf', 'archive';
    unlink 'archive';
  
    my $source = do {
      my @children = map { $_->absolute } dir()->children;
      if(@children != 1)
      {
        say "archive doesn't contain exactly one child: @children";
      }
  
      $CWD = $children[0]->stringify;
      $children[0];
    };
  
    say "merge...";
  
    foreach my $child ($dest->children)
    {
      next if $child->basename eq '.git';
      system 'rm', '-rf', "$child";
    }
  
    foreach my $child ($source->children)
    {
      system 'cp', '-ar', "$child", "$dest";
    }
  
    say "commit and tag...";
    $git->add('.');
    $git->rm($_->from) for grep { $_->mode eq 'deleted' } $git->status->get('changed');
    $git->commit({
      message => "version $version",
      date    => "$date +0000",
      author  => author $cpanid,
    });
    $git->tag($version);
  }
  
  return 0;
}

1;
