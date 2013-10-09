# cpan2git

Convert cpan distribution from BackPAN to a git repository

# SYNOPSIS

    % cpan2git Foo::Bar

# DESCRIPTION

This script fetches all known revisions of a distribution from CPAN/BackPAN
and creates a git repository with one revision and one tag for each version
of the distribution.

# OPTIONS

## \--help | -h

Print out help and exit.

## \--version

Print out version and exit.

# CAVEATS

If the distribution name has changed, this script has no way of knowing it
and so only revisions with the same name will be included.  Possible 
feature would include specifying multiple distribution names in the command
line.

Currently only works on UNIX like operating systems with rm, cp and a tar which
automatically decompresses compressed tars.

There isn't a test aside from making sure [App::cpan2git](http://search.cpan.org/perldoc?App::cpan2git) compiles.

Patches are welcome.

# AUTHOR

Graham Ollis <plicease@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
