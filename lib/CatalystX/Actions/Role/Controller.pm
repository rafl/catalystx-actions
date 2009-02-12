package CatalystX::Actions::Role::Controller;

use Moose::Role;
use Moose::Util qw/find_meta/;

use namespace::clean -except => 'meta';

after register_actions => sub {
    my ($self, $app) = @_;

    #TODO: don't assume the action_methods method exists
    #TODO: walk the superclasses to collect all actions
    my @methods = find_meta($self)->action_methods;

    for my $method (@methods) {
        my $action = $self->create_action_from_method($app, $method);
        $app->dispatcher->register($app, $action);
    }
};

sub create_action_from_method {
    my ($self, $app, $method) = @_;
    my $name = $method->name;

    my $namespace = $self->action_namespace($app);
    my $reverse   = $namespace ? "${namespace}/${name}" : $name;

    my $attrs = $method->isa('Class::MOP::Method::Wrapped')
        ? $method->get_original_method->attributes
        : $method->attributes;

    return $self->create_action(
        name       => $name,
        code       => $method->body,
        reverse    => $reverse,
        namespace  => $namespace,
        class      => blessed($self) || $self,
        attributes => $self->_parse_action_attrs($app, $method->name, $attrs),
    );
}

# FIXME: this is mostly copied from Catalyst::Controller::_parse_attrs
sub _parse_action_attrs {
    my ($self, $app, $method, $attrs) = @_;

    my $actions;
    if (ref $self) {
        $actions = $self->actions;
    }
    else {
        my $cfg = $self->config;
        $actions = $self->merge_config_hashes($cfg->{actions}, $cfg->{action});
    }

    my %raw = (
        (exists $actions->{'*'} ? %{$actions->{'*'}} : ()),
        %{ $attrs },
        (exists $actions->{$method} ? %{$actions->{$method}} : ()),
    );

    my %final;
    while (my ($k, $v) = each %raw) {
        my $meth = qq{_parse_${k}_attr};
        if (my $code = $self->can($meth)) {
            ($k, $v) = $self->$code($app, $method, $v);
        }

        push @{ $final{$k} }, $v;
    }

    return \%final;
}

1;
