package CatalystX::Actions::Meta::Role::Controller;

use Moose::Role;
use Class::MOP;
use MooseX::Types::Moose qw/Str/;

use namespace::clean -except => 'meta';

has action_method_metaclass => (
    is       => 'ro',
    isa      => Str,
    required => 1,
    default  => 'CatalystX::Actions::Meta::Method',
);

#FIXME: BUILD apparently isn't the right thing to use in a role
use CatalystX::Actions::Meta::Method;

sub BUILD {
    my ($self) = @_;
    Class::MOP::load_class($self->action_method_metaclass);
}

sub add_action {
    my ($self, $name, $code, %attrs) = @_;
    $self->add_method(
        $name => $self->action_method_metaclass->wrap(
            body => $code, name => $name,
            package_name => $self->name, attributes => \%attrs,
        ),
    );
}

sub action_methods {
    my ($self) = @_;
    my $method_class = $self->action_method_metaclass;
    return grep {
        $_->isa('Class::MOP::Method::Wrapped')
            ? $_->get_original_method->isa($method_class)
            : $_->isa($method_class)
    } $self->get_all_methods;
}

1;
