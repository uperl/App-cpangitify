# cpangitify ![static](https://github.com/uperl/App-cpangitify/workflows/static/badge.svg) ![linux](https://github.com/uperl/App-cpangitify/workflows/linux/badge.svg)

Convert cpan distribution from BackPAN to a git repository

# SYNOPSIS

```
% cpangitify Foo::Bar
```

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
for the repository).  For example [Mojolicious::Plugin::TtRenderer](https://metacpan.org/pod/Mojolicious::Plugin::TtRenderer) was
once called `MojoX::Renderer::TT`, so you would get both names in the
history like this:

```
% cpangitify Mojolicious::Plugin::TtRenderer MojoX::Renderer::TT
```

# OPTIONS

## --resume

Resume the import from CPAN.  Note that any local changes will be overwritten
by the CPAN upstream (your modifications will remain in the repository history).

## --output | -o _directory_

Creat the new repository in the given directory.

## --skip _version_

Skip the given versions.  Can be specified multiple times and can
be provided as a comma separated list.

## --trace

Print each git command before it is executed.

## --backpan\_index\_url

The URL to use for the BackPAN index

## --backpan\_url

The URL to use for BackPAN

## --metacpan\_url

The URL to use for metacpan.

## --branch | -b

Default branch.  As on 0.18 this is `main` by default.  Previously the old
git default was used.

## --help | -h

Print out help and exit.

## --version

Print out version and exit.

# CAVEATS

Each commit belongs to the CPAN author who submitted the corresponding release,
therefore `git blame` may not be that useful for the imported portion of
your new repository history.

The commits are ordered by date, so where there are interleaving of releases
that belong to development and production branches this simple minded script
will probably do the wrong thing.

Patches are welcome.

# SEE ALSO

Here are some similar projects:

- [Git::CPAN::Patch](https://metacpan.org/pod/Git::CPAN::Patch)

    Comes with a `git cpan import` which does something similar.  With this
    incantation I was able to get a repository for [YAML](https://metacpan.org/pod/YAML) (including history,
    but without authors and without the correct dates):

    ```
    % mkdir YAML
    % git init .
    % git cpan import --backpan YAML
    % git merge remotes/cpan/master
    ```

    One advantage here over `cpangitify` is that you should then later be able to
    import/merge future CPAN releases into yours.  [Git::CPAN::Patch](https://metacpan.org/pod/Git::CPAN::Patch) also has a bunch of
    other useful tools for creating and submitting patches and may be worth
    checking out.

    If you do an internet search for this sort of thing you may see references
    to `git-backpan-init`, but this does not appear to be part of the
    [Git::CPAN::Patch](https://metacpan.org/pod/Git::CPAN::Patch) anymore (I believe `git-import` with the `--backpan`
    option is the equivalent).

    In general `cpangitify` is a one trick poney (though good at that one thing),
    and [Git::CPAN::Patch](https://metacpan.org/pod/Git::CPAN::Patch) is a Batman's utility belt with documentation that
    (for me at least) is pretty impenetrable.

- [gitpan](https://github.com/gitpan)

    Doesn't appear to have been updated in a number of years.

- [ggoosen's cpan2git](https://github.com/ggoossen/cpan2git)

The reason I am not using the latter two is that they are designed to
mirror the whole of CPAN/BackPAN, but I'm mostly just interested in one
or two distributions here and there.

# AUTHOR

Author: Graham Ollis <plicease@cpan.org>

Contributors:

Mohammad S Anwar (MANWAR)

# COPYRIGHT AND LICENSE

This software is copyright (c) 2013-2022 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
