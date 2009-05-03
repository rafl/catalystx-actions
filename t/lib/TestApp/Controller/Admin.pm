controller TestApp::Controller::Admin {
    chain base at '/admin' () {
        $ctx->detach('/error_404')
            unless $ctx->user_exists && $ctx->user->has_role('admin');
    }

    action index at '/' () {}
}

1;
