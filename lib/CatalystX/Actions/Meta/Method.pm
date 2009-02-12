package CatalystX::Actions::Meta::Method;

use Moose;

use namespace::clean -except => 'meta';

extends qw/Moose::Meta::Method/;

has attributes => (
    is => 'ro',
);

around wrap => sub {
    my ($next, $class, %args) = @_;
    my $attributes = delete $args{attributes};
    my $self = $class->$next(%args);
    $self->meta->get_attribute('attributes')->set_value($self, $attributes);
    return $self;
};

__PACKAGE__->meta->make_immutable;

1;
