package Perinci::CmdLine::Easy;

use 5.010001;
use strict;
use warnings;
use Perinci::CmdLine;

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(run_cmdline_app);

our $DATE = '2014-07-03'; # DATE
our $VERSION = '1.16'; # VERSION

our %SPEC;

$SPEC{run_cmdline_app} = {
    v       => 1.1,
    summary => "A simple interface to run a subroutine as command-line app",
    args    => {
        sub => {
            req => 1,
            summary => "Coderef or subroutine name",
        },
        summary => {
            schema => "str*",
        },
        description => {
            schema => "str*",
        },
        argv => {
            schema  => ["array*" => {of=>"str*", default=>[]}],
            summary => "List of arguments",
            description => <<'_',

Each argument is NAME, NAME* (marking required argument), or NAME+ (marking
greedy argument, where the rest of command-line arguments will be fed into this
array).

_
        },
    },
    result_naked => 1,
    "_perinci.sub.wrapper.validate_args" => 0,
};
sub run_cmdline_app {
    my %args = @_; require List::Util;my $_sahv_dpath = []; my $arg_err; ($args{'argv'} //= [], 1) && ((defined($args{'argv'})) ? 1 : (($arg_err //= (@$_sahv_dpath ? '@'.join("/",@$_sahv_dpath).": " : "") . "Required input not specified"),0)) && ((ref($args{'argv'}) eq 'ARRAY') ? 1 : (($arg_err //= (@$_sahv_dpath ? '@'.join("/",@$_sahv_dpath).": " : "") . "Input is not of type array"),0)) && ((push(@$_sahv_dpath, undef), (!defined(List::Util::first(sub {!( ($_sahv_dpath->[-1] = defined($_sahv_dpath->[-1]) ? $_sahv_dpath->[-1]+1 : 0), ((defined($_)) ? 1 : (($arg_err //= (@$_sahv_dpath ? '@'.join("/",@$_sahv_dpath).": " : "") . "Required input not specified"),0)) && ((!ref($_)) ? 1 : (($arg_err //= (@$_sahv_dpath ? '@'.join("/",@$_sahv_dpath).": " : "") . "Input is not of type text"),0)) )}, @{$args{'argv'}})))) ? 1 : (($arg_err //= (@$_sahv_dpath ? '@'.join("/",@$_sahv_dpath).": " : "") . "Input is not of type text", pop(@$_sahv_dpath)),0)); if ($arg_err) { return [400, "Invalid argument value for argv: $arg_err"] } if (exists($args{'description'})) { ((defined($args{'description'})) ? 1 : (($arg_err //= (@$_sahv_dpath ? '@'.join("/",@$_sahv_dpath).": " : "") . "Required input not specified"),0)) && ((!ref($args{'description'})) ? 1 : (($arg_err //= (@$_sahv_dpath ? '@'.join("/",@$_sahv_dpath).": " : "") . "Input is not of type text"),0)); if ($arg_err) { return [400, "Invalid argument value for description: $arg_err"] } }if (!exists($args{'sub'})) { return [400, "Missing argument: sub"] } if (exists($args{'summary'})) { ((defined($args{'summary'})) ? 1 : (($arg_err //= (@$_sahv_dpath ? '@'.join("/",@$_sahv_dpath).": " : "") . "Required input not specified"),0)) && ((!ref($args{'summary'})) ? 1 : (($arg_err //= (@$_sahv_dpath ? '@'.join("/",@$_sahv_dpath).": " : "") . "Input is not of type text"),0)); if ($arg_err) { return [400, "Invalid argument value for summary: $arg_err"] } }# VALIDATE_ARGS

    my $meta = {
        v            => 1.1,
        summary      => $args{summary},
        description  => $args{description},
        result_naked => 1,
        args_as      => "array",
        args         => {},
    };

    my $i = 0;
    for my $arg (@{ $args{argv} // []}) {
        my $req    = $arg =~ s/\*$//;
        my $greedy = $arg =~ s/\+$//;

        $meta->{args}{$arg} = {
            pos     => $i,
            req     => $req,
            greedy  => $greedy,
            summary => "Argument #$i",
            schema  => "str*",
        };
        $i++;
    }

    my @caller = caller(1);

    no strict 'refs';
    my $sub = $args{sub};
    my $url;
    if (!$sub) {
        die "Please supply sub\n";
    } elsif (ref($sub) eq 'CODE') {
        my $name = "$sub";
        $name =~ s/[^A-Za-z0-9]+//g;
        $main::SPEC{$name} = $meta;
        *{ "main::$name" } = $sub;
        $url = "/main/$name";
    } else {
        my ($pkg, $local) = $sub =~ /\A(.+::)?(.+)\z/;
        $pkg = $caller[0] . '::' unless $pkg;
        ${ $pkg . "SPEC" }{$local} = $meta;
        $url = $pkg;
        $url =~ s!::!/!g;
        $url = "/$url";
    }

    Perinci::CmdLine->new(url => $url)->run;
}

1;
# ABSTRACT: A simple interface to run a subroutine as command-line app

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::CmdLine::Easy - A simple interface to run a subroutine as command-line app

=head1 VERSION

This document describes version 1.16 of Perinci::CmdLine::Easy (from Perl distribution Perinci-CmdLine-Easy), released on 2014-07-03.

=head1 SYNOPSIS

In your command-line script (e.g. named list-cpan-dists):

 use JSON qw(decode_json);
 use LWP::Simple;
 use Perinci::CmdLine::Easy qw(run_cmdline_app);
 run_cmdline_app(
     summary => "List CPAN distributions that belong to an author",
     sub     => sub {
         my $cpanid = shift or die "Please supply CPAN ID\n";
         my $res = get "http://api.metacpan.org/v0/release/_search?q=author:".
             uc($cpanid)."%20AND%20status:latest&fields=name&size=5000"
             or die "Can't query MetaCPAN";
         $res = $json->decode($res);
         die "MetaCPAN timed out\n" if $res->{timed_out};
         my @dists;
         for my $hit (@{ $res->{hits}{hits} }) {
             my $dist = $hit->{fields}{name};
             $dist =~ s/-\d.+//;
             push @dists, $dist;
         }
         \@dists;
     },
     argv    => [qw/cpanid*/],
 );

To run this program:

 % list-cpan-dists --help ;# display help message
 % LANG=id_ID list-cpan-dists --help ;# display help message in Indonesian
 % list-cpan-dists SHARYANTO

To do bash tab completion:

 % complete -C list-cpan-dists list-cpan-dists
 % list-cpan-dists <tab> ;# completes to --help, --version, --cpanid, etc
 % list-cpan-dists --c<tab> ;# completes to --cpanid

=head1 DESCRIPTION

Perinci::CmdLine::Easy provides an easier alternative to L<Perinci::CmdLine>.
You do not need to know any L<Rinci> or L<Riap> concepts, or provide your own
metadata. Just supply the subroutine, summary, list of arguments, and you're
good to go. Of course, if you need more customization, there's Perinci::CmdLine.

What you'll get:

=over 4

=item * Command-line options parsing

=item * Help message (supports translation)

=item * Tab completion for bash

=item * Formatting of output (supports complex data structure)

=item * Logging

=back

=head1 FUNCTIONS


=head2 run_cmdline_app(%args) -> any

A simple interface to run a subroutine as command-line app.

Arguments ('*' denotes required arguments):

=over 4

=item * B<argv> => I<array> (default: [])

List of arguments.

Each argument is NAME, NAME* (marking required argument), or NAME+ (marking
greedy argument, where the rest of command-line arguments will be fed into this
array).

=item * B<description> => I<str>

=item * B<sub>* => I<any>

Coderef or subroutine name.

=item * B<summary> => I<str>

=back

Return value:

=for Pod::Coverage .+

=head1 SEE ALSO

L<Perinci::CmdLine>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-CmdLine-Easy>.

=head1 SOURCE

Source repository is at L<https://github.com/sharyanto/perl-Perinci-CmdLine-Easy>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-CmdLine-Easy>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Steven Haryanto <stevenharyanto@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Steven Haryanto.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
