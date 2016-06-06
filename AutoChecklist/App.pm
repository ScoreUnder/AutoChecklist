# Copyright 2016 "Score_Under"; distributed under the terms of the GPLv2 (or
# later versions, at your option) as published by the Free Software Foundation
use 5.012;
use strict;
use warnings;

use Carp qw/confess/;

use AutoChecklist::Checklist ();
use AutoChecklist::Item ();

sub read_checklist {
    my ($listfname) = @_;
    confess 'Wrong number of args' if @_ != 1;

    # TODO is enum a sensible dependency?
    use enum qw/ NONE SOURCES CHECKLIST IGNORE /;
    my $parse_state = NONE;

    my @sources;
    my @raw_sources;
    my @checklists;
    my %ignore;
    my $curr_list;

    # Not using utf-8 because there's no point "understanding" most chars
    # Also NYTProf identified it as a bottleneck :^)
    open my $listfh, '<', $listfname
        or die "Could not open checklist for reading: $!\n";
    while (<$listfh>) {
        next if /^\s*($|#)/;

        # Parse sources if a "From" section is encountered
        if (/^\s* From: \s*$/x) {
            $parse_state = SOURCES;
            next;
        }

        if (/^\s* Ignore: \s*$/x) {
            $parse_state = IGNORE;
            next;
        }

        # Parse a checklist if something in "x = y:" or "= y:" form is
        # encountered
        if (/^(?:(.*\S)\s+)? = \s+ (\S+.*): \s*$/x) {
            $parse_state = CHECKLIST;
            $curr_list = AutoChecklist::Checklist->new($2, $1);
            push @checklists, $curr_list;
            next;
        }

        # Parse a source name if it begins with "- ".
        if (/^- \s+ (\S.*?) \s*$/x) {
            if ($parse_state == SOURCES) {
                push @raw_sources, $1;
                my @new_sources = glob $1;

                if (!@new_sources) {
                    warn "Warning: Source does not exist: $1\n";
                } else {
                    for my $source (@new_sources) {
                        if (!-e $source) {
                            warn "Warning: Source does not exist: $source (from $1)\n";
                        } elsif (!-d _) {
                            warn "Warning: Source is not a directory: $source (from $1)\n";
                        } elsif (!-r _) {
                            warn "Warning: Source is not readable: $source (from $1)\n";
                        } elsif ($source =~ /\n|^\s|\s$/) {
                            warn "Warning: Tricky dir name (contains newlines, or has leading/trailing spaces), ignored: $source (from $1)\n";
                        } else {
                            push @sources, $source;
                        }
                    }
                }
            } elsif ($parse_state == IGNORE) {
                $ignore{$1} = 1;
            } else {
                die qq{Found something that looks like a source, but }
                   .qq{is outside of the "From" or "Ignore" list.\n}
                   .qq{Line in question (line $.):\n\t$_\n};
            }
            next;
        }

        # Parse a checklist item if it looks like "[???] ???"
        if (/^\[ ([^\]]+) \] \s+ (\S.*?) \s*$/x) {
            die qq{Found something that looks like a checklist item, }
               .qq{but that is outside of a checklist.\n}
               .qq{Line in question (line $.):\n\t$_\n}
                if $parse_state != CHECKLIST;

            $curr_list->add(AutoChecklist::Item->new($2, $1));
            next;
        }

        die "Couldn't parse line $.. Contents:\n\t$_\n";
    }

    (\@checklists, \@sources, \@raw_sources, \%ignore)
}

sub find_new_checklists {
    my ($checklists, $sources, $existing_checklists) = @_;
    confess 'Wrong number of args' if @_ != 3;

    for (@{$sources}) {
        next if $$existing_checklists{$_};
        $$existing_checklists{$_} = 1;
        push @{$checklists}, AutoChecklist::Checklist->new($_);
    }
}

sub split_checklists {
    my ($checklists, $ignore, $existing_checklists) = @_;
    confess 'Wrong number of args' if @_ != 3;

    for my $checklist (@$checklists) {
        my @new = map {$_->path} $checklist->remove_checks('s');
        for (@new) {
            my $path = $checklist->path . '/' . $_;
            $$ignore{$path} = 1;
            next if $$existing_checklists{$path};
            $$existing_checklists{$path} = 1;
            push @$checklists, AutoChecklist::Checklist->new($path);
        }
    }
}

sub populate_checklists {
    my ($checklists, $ignore) = @_;
    confess 'Wrong number of args' if @_ != 2;

    for my $checklist (@$checklists) {
        $$ignore{$checklist->path.'/'.$_->path} = 1 for $checklist->remove_checks('i');
        eval {
            $checklist->find_new_items($ignore);
        };
        if ($@) {
            warn $@;
        }
    }
}

sub print_list {
    my ($where, $heading, @list) = @_;

    print $where "$heading:\n";
    for (@list) {
        print $where "- $_\n";
    }
}

sub print_checklists {
    my ($where, @checklists) = @_;

    for my $checklist (@checklists) {
        print $where "\n";
        if ($checklist->name) {
            print $where $checklist->name, " = ", $checklist->path, ":\n";
        } else {
            print $where "= ", $checklist->path, ":\n";
        }

        for my $item (@{$checklist->items}) {
            printf $where "[%s] %s\n", $item->check, $item->path;
        }
    }
}

sub main {
    die "Need exactly one argument (name of checklist file)" if @ARGV != 1;
    my $listfname = $ARGV[0];

    my ($checklists, $sources, $raw_sources, $ignore) = read_checklist $listfname;

    # Modify checklists as appropriate
    my %existing_checklists = map {$_->path => 1} @{$checklists};
    find_new_checklists $checklists, $sources, \%existing_checklists;
    split_checklists    $checklists, $ignore,  \%existing_checklists;
    populate_checklists $checklists, $ignore;

    # Output checklists again
    open my $outfile, '>', $listfname
        or die "Could not open checklist for writing: $!\n";
    print_list $outfile, 'From', @$raw_sources;
    print_checklists $outfile, @$checklists;
    print $outfile "\n";
    print_list $outfile, 'Ignore', sort keys %$ignore;
}

1;
