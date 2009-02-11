use strict;
use warnings;

package TestApp::Controller::Root;

use parent qw/Catalyst::Controller/;

use CatalystX::Actions::Declare;

action base => (Chained => '/', PathPart => '', CaptureArgs => 0) => sub {};

action default => (Chained => 'base', PathPart => '', Args => undef) => sub {};

action index => (Chained => 'base', PathPart => '', Args => 0) => sub {
    my ($self, $c) = @_;
    $c->response->body('OH HAI!');
};

no CatalystX::Actions::Declare;

1;
