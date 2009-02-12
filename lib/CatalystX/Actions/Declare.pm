package CatalystX::Actions::Declare;

use strict;
use warnings;

use Moose ();
use Moose::Util qw/find_meta/;
use Moose::Exporter;

use namespace::clean;

Moose::Exporter->setup_import_methods(
    with_caller => [qw/action/],
    also        => [qw/Moose/],
);

sub init_meta {
    my ($class, %args) = @_;
    my $meta = Moose->init_meta(%args);

    my $controller_role      = $args{controller_role}      || 'CatalystX::Actions::Role::Controller';
    my $controller_meta_role = $args{controller_meta_role} || 'CatalystX::Actions::Meta::Role::Controller';

    Moose::Util::MetaRole::apply_metaclass_roles(
        for_class       => $args{for_class},
        metaclass_roles => [$controller_meta_role],
    );

    Moose::Util::MetaRole::apply_base_class_roles(
        for_class => $args{for_class},
        roles     => [$controller_role],
    );

    return $meta;
}

sub action {
    my ($caller, $name, @args) = @_;
    my $code = pop @args;
    find_meta($caller)->add_action($name, $code, @args);
    return;
}

1;
