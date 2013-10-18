package inc::MakeMaker;

use Moose;
use namespace::autoclean;
use v5.10;

with 'Dist::Zilla::Role::InstallTool';

sub setup_installer
{
  my($self) = @_;
  
  my($makefile) = grep { $_->name eq 'Makefile.PL' } @{ $self->zilla->files };
  
  my $content = $makefile->content;

  state $data;
  $data = do { local $/; <DATA> } unless $data;

  if($content =~ s{^WriteMakefile}{$data\nWriteMakefile}m)
  {
    $makefile->content($content);
    $self->log("Modified Makefile.PL");
  }
  else
  {
    $self->log_fatal("unable to update Makefile.PL");
  }
}

1;

__DATA__

use Git::Wrapper;
use Sort::Versions qw( versioncmp );

if ( versioncmp( Git::Wrapper->new(".")->version , '1.5.0') eq -1 ) {
  print "git version 1.5.0 or better is required\n";
  exit 2;
}
