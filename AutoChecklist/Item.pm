# Copyright 2016 "Score_Under"; distributed under the terms of the GPLv2 (or
# later versions, at your option) as published by the Free Software Foundation
package AutoChecklist::Item;
use Carp qw/confess/;

sub new {
    my ($class, $path, $check) = @_;
    confess 'Wrong number of args' if @_ != 3 and @_ != 2;
    bless([$check // ' ', $path], $class)
}
sub check() :lvalue { $_[0][0] }
sub path()  { $_[0][1] }

1;
