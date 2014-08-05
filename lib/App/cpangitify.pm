package App::cpangitify;

use strict;
use warnings;
use autodie qw( :system );
use v5.10;
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
use File::Copy::Recursive qw( rcopy );
use File::Basename qw( basename );
use Archive::Extract;
use File::Spec;
use CPAN::ReleaseHistory;

# ABSTRACT: Convert cpan distribution from BackPAN to a git repository
# VERSION

=head1 DESCRIPTION

This is the module for the L<cpangitify> script.  See L<cpangitify> for details.

=head1 SEE ALSO

L<cpangitify>

=cut

our $ua  = LWP::UserAgent->new;
our $opt_metacpan_url;

sub _rm_rf
{
  my($file) = @_;
  
  if($file->is_dir && ! -l $file)
  {
    _rm_rf($_) for $file->children;
  }
  
  $file->remove || die "unable to delete $file";
}

sub main
{
  my $class = shift;
  local @ARGV = @_;
  
  my $opt_backpan_index_url;
  my $opt_backpan_url = "http://backpan.perl.org/authors/id";
  $opt_metacpan_url   = "http://api.metacpan.org/";

  GetOptions(
    'backpan_index_url=s' => \$opt_backpan_index_url,
    'backpan_url=s'       => \$opt_backpan_url,
    'metacpan_url=s'      => \$opt_metacpan_url,
    'help|h'              => sub { pod2usage({ -verbose => 2}) },
    'version'             => sub {
      say 'cpangitify version ', ($App::cpangitify::VERSION // 'dev');
      exit 1;
    },
  ) || pod2usage(1);

  my @names = map { s/::/-/g; $_ } @ARGV;
  my %names = map { $_ => 1 } @names;
  my $name = $names[0];

  pod2usage(1) unless $name;

  my $dest = dir()->absolute->subdir($name);

  if(-e $dest)
  {
    say "already exists: $dest";
    return 2;
  }

  say "creating/updating index...";
  my $history = CPAN::ReleaseHistory->new(
    maybe url => $opt_backpan_index_url
  )->release_iterator;

  say "searching...";
  my @rel;
  while(my $release = $history->next_release)
  {
    next unless $names{$release->distinfo->dist};
    push @rel, $release;
  }

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
    my $version = $rel->distinfo->version;
    my $time    = $rel->timestamp;
    my $cpanid  = $rel->distinfo->cpanid;
  
    say "$path [ $version ]";
  
    my $tmp = dir( tempdir( CLEANUP => 1 ) );
  
    local $CWD = $tmp->stringify;
  
    my $uri = URI->new(join('/', $opt_backpan_url, $path));
    say "fetch ... $uri";
    my $res = $ua->get($uri);
    unless($res->is_success)
    {
      say "error fetching $uri";
      say $res->status_line;
      return 2;
    }
  
    do {
      my $fn = basename $uri->path;
    
      open my $fh, '>', $fn;
      print $fh $res->decoded_content;
      close $fh;

      say "unpack... $fn";
      my $archive = Archive::Extract->new( archive => $fn );
      $archive->extract( to => File::Spec->curdir ) || die $archive->error;
      unlink $fn;
  
    };
  
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
      _rm_rf($child);
    }
  
    foreach my $child ($source->children)
    {
      if(-d  $child)
      {
        rcopy($child, $dest->subdir($child->basename)) || die "unable to copy $child $!";
      }
      else
      {
        rcopy($child, $dest->file($child->basename)) || die "unable to copy $child $!";
      }
    }
  
    say "commit and tag...";
    $git->add('.');
    $git->rm($_->from) for grep { $_->mode eq 'deleted' } $git->status->get('changed');
    $git->commit({
      message => "version $version",
      date    => "$time +0000",
      author  => author $cpanid,
    });
    eval { $git->tag($version) };
    warn $@ if $@;
  }
  
  return 0;
}

1;
