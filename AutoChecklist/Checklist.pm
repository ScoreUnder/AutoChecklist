# Copyright 2016 "Score_Under"; distributed under the terms of the GPLv2 (or
# later versions, at your option) as published by the Free Software Foundation
package AutoChecklist::Checklist;
use 5.016;
use Carp qw/confess croak/;

sub new {
    my ($class, $path, $name) = @_;
    confess 'Got a ref for $path' if ref $path;
    confess 'Wrong number of args' if @_ != 3 and @_ != 2;
    bless([$name // '', $path, []], $class)
}

sub name()  { $_[0][0] }
sub path()  { $_[0][1] }
sub items() { $_[0][2] }

sub add {
    my ($self, $item) = @_;
    confess 'Wrong number of args' if @_ != 2;
    push @{$self->items}, $item;
}

sub remove_checks {
    my ($self, $check) = @_;
    confess 'Wrong number of args' if @_ != 2;

    $check = fc $check;
    my @result;
    for (my $i = 0; $i <= $#{$self->items}; $i++) {
        my $item = $self->items()->[$i];
        next unless fc($item->check) eq $check;

        push @result, $item;
        splice @{$self->items}, $i, 1;
        $i--;
    }
    @result;
}

sub find_new_items {
    my ($self, $ignore) = @_;
    confess 'Wrong number of args' if @_ != 2;

    my %already_have = map {$_->path => 1} @{$self->items};

    my $path = $self->path;
    opendir my $dh, $path or croak "Can't open dir $path: $!";
    my @files = readdir $dh;
    closedir $dh;

    @files = sort @files;

    for (@files) {
        next if $already_have{$_} or /^\./ or $$ignore{"$path/$_"};
        if (/\n|^[\t ]|[\t ]$/) {
            warn "Warning: Tricky filename (contains newlines, or has leading/trailing spaces), ignored: $_\n";
            next;
        }
        $self->add(AutoChecklist::Item->new($_));
    }
}

1;
