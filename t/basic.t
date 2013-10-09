use strict;
use warnings;
use File::HomeDir::Test;
use File::HomeDir;
use Test::More tests => 1;
use App::cpan2git;
use Capture::Tiny qw( capture_merged );
use File::chdir;
use URI::file;
use Path::Class qw( file dir );

my $home = File::HomeDir->my_home;

do {
  local $CWD = "$home";
  my $ret;
  
  my @args = (
    '--backpan_index_url' => "file://localhost/home/ollisg/dev/App-cpan2git/t/backpan/backpan-index.txt.gz",
    '--backpan_url'       => "file://localhost/home/ollisg/dev/App-cpan2git/t/backpan",
    'Foo::Bar',
  );
  
  my $merged = capture_merged { $ret = App::cpan2git->main(@args) };
  is($ret, 0, "% cpan2git @args");
  note $merged;
};

