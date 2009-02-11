package CatalystX::Actions::Declare;

use strict;
use warnings;

use Moose::Util qw/find_meta/;
use Moose::Meta::Class;
use Moose::Exporter;

sub fake_attrs {
    my (@args) = @_;
    my @ret;
    while (@args) {
        my ($k, $v) = splice @args, 0, 2;
        push @ret, qq{${k}(} . (defined $v ? qq{'${v}'} : q{}) . qq{)};
    }
    return @ret;
}

use namespace::clean;

Moose::Exporter->setup_import_methods(
    with_caller => [qw/action/],
);

sub action {
    my ($caller, $name, @args) = @_;
    my $code = pop @args;

    my $meta = find_meta($caller) || Moose::Meta::Class->initialize($caller);
    $meta->add_method($name => $code);

    push @{ $caller->_action_cache }, [$code, [fake_attrs @args]];

    return;
}

1;
