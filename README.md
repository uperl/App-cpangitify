# cpangitify [![Build Status](https://secure.travis-ci.org/plicease/App-cpangitify.png)](http://travis-ci.org/plicease/App-cpangitify)

Convert cpan distribution from BackPAN to a git repository

# SYNOPSIS

    % cpangitify Foo::Bar

# DESCRIPTION

This script fetches all known revisions of a distribution from CPAN/BackPAN
and creates a git repository with one revision and one tag for each version
of the distribution.

The idea is to create a starting point for a git work flow when adopting a
CPAN module for which you don't have access to the original repository.
It is of course better to import from Subversion or to clone an existing
git repository, but that may not be an option.

If the distribution you are migrating changed names during its history,
simply specify each name it had on the command line.  Be sure to specify
the current name first (this will be used when creating a directory name
for the repository).  For example [Mojolicious::Plugin::TtRenderer](http://search.cpan.org/perldoc?Mojolicious::Plugin::TtRenderer) was
once called [MojoX::Renderer::TT](http://search.cpan.org/perldoc?MojoX::Renderer::TT), so you would get both names in the
history like this:

    % cpangitify Mojolicious::Plugin::TtRenderer MojoX::Renderer::TT

# OPTIONS

## \--help | -h

Print out help and exit.

## \--version

Print out version and exit.

# CAVEATS

Currently only works on UNIX like operating systems with rm, cp and a tar which
automatically decompresses compressed tars.

Each commit belongs to the CPAN author who submitted the corresponding release,
therefore `git blame` may not be that useful for the imported portion of
your new repository history.

The commits are ordered by date, so where there are interleaving of releases
that belong to development and production branches this simple minded script
will probably do the wrong thing.

Patches are welcome.

# SEE ALSO

Here are some similar projects:

- [gitpan](https://github.com/gitpan)

    Doesn't appear to have been updated in a number of years.

- [ggoosen's cpan2git](https://github.com/ggoossen/cpan2git)

The reason I am not using them is that they are designed to mirror the 
whole of CPAN/BackPAN, but I'm mostly just interested in one or two 
distributions here and there.

# AUTHOR

Graham Ollis <plicease@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
