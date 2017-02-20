package Syntax::Feature::RawQuote;
use strict;
use warnings;
use XSLoader;

BEGIN {
  our $VERSION = '0.01';
  XSLoader::load(__PACKAGE__);
}

sub install {
  my ($class, %args) = @_;

  my $keyword = $args{options}{"-as"} || "r";
  $^H{+HINTK_KEYWORDS} .= ",$keyword";
  return 1;
}

sub uninstall {
  $^H{+HINTK_KEYWORDS} = "";
  return 1;
}

1;

__END__

=head1 NAME

Syntax::Feature::RawQuote - do raw quotes

=head1 AUTHOR

Andrew Rodland <arodland@cpan.org>

=head1 LICENSE

Copyright (c) Andrew Rodland.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
