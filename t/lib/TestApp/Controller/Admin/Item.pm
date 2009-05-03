controller TestApp::Controller::Admin::Item extends TestApp::ControllerBase::CollectionEditor {
    __PACKAGE__->config(
        model_name      => 'DB',
        collection_name => 'Item',
        search_fields   => [qw/name note/],
        actions         => {
            base => { Chained => '../base', PathPart => 'item' },
            list => { Chained => 'limit' },
        },
    );

    override _build_list_actions {
        my $actions = super;
        push @{ $actions }, {
            name  => 'approve_many',
            label => 'Approve Selected',
        };
        return $actions;
    }

    override get_collection ($ctx) {
        return super->order_by('submitted_at');
    }

    before create_row ($form) {
        $form->add_valid(source => 'trusted');
        $form->add_valid(status => 'approved');
    }

    chain limit at '/' () {
        $ctx->stash(collection => $ctx->stash->{collection}->from_untrusted_source)
            unless defined $ctx->request->param('q');
    }

    under object, action approve () {
        $ctx->stash->{object}->approve;
        $ctx->response->redirect( $ctx->uri_for($self->action_for('list')) );
    }

    method approve_many ($ctx, $rows) {
        $rows->approve;
        $ctx->response->redirect( $ctx->uri_for($self->action_for('list')) );
    }
}

1;
