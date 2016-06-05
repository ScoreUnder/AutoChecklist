package AutoChecklist::Item;
use Carp qw/confess/;

sub new {
    my ($class, $path, $check) = @_;
    confess 'Wrong number of args' if @_ != 3 and @_ != 2;
    bless([$check // ' ', $path], $class)
}
sub check() { $_[0][0] }
sub path()  { $_[0][1] }

1;
