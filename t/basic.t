use strict;
use warnings;
use Test::More tests => 3;

use FindBin;
use lib "$FindBin::Bin/lib";

BEGIN { use_ok('TestApp') }

use Catalyst::Test 'TestApp';

{
    my $resp = request('/');
    ok($resp->is_success);
    is($resp->content, 'OH HAI!');
}
