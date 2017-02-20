package Syntax::Keyword::RawQuote;
use strict;
use warnings;
use XSLoader;

BEGIN {
  our $VERSION = '0.01';
  XSLoader::load(__PACKAGE__);
}

sub import {
  my ($class, %args) = @_;

  my $keyword = $args{"-as"} || "r";
  $^H{+HINTK_KEYWORDS} .= ",$keyword";
}

sub uninstall {
  my ($class, %args) = @_;
  if ($args{"-as"}) {
    $^H{+HINTK_KEYWORDS} =~ s/,\Q$args{"-as"}\E//;
  } else {
    $^H{+HINTK_KEYWORDS} = "";
  }
}

1;

__END__

=head1 NAME

Syntax::Keyword::RawQuote - do raw quotes

=head1 AUTHOR

Andrew Rodland <arodland@cpan.org>

=head1 LICENSE

Copyright (c) Andrew Rodland.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
