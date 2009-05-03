package TstApp::ControllerBase::CollectionEditor;

controller ControllerBase::CollectionEditor {
    has model_name      => (is => 'ro', isa => Str, required => 1);
    has collection_name => (is => 'ro', isa => Str, required => 1);

    has search_fields => (
        is       => 'ro',
        isa      => ArrayRef[Str],
        required => 1,
    );

    has list_actions => (
        is       => 'ro',
        isa      => ArrayRef[HashRef[Str]],
        required => 1,
        builder  => '_build_list_actions',
    );

    has row_actions => (
        is       => 'ro',
        isa      => ArrayRef [Str],
        required => 1,
        builder  => '_build_row_actions',
    );

    method _build_row_actions {
        return [qw/view edit delete/];
    }

    method _build_list_actions {
        return [{ name => 'delete_many', label => 'Delete Selected' }];
    }

    method get_collection ($ctx) {
        return $ctx->model( $self->model_name )->resultset( $self->collection_name );
    }

    method create_row ($form) {
        $form->model->create;
    }

    method update_row ($form, $object) {
        $form->model->update($object);
    }

    method defaults_from_row ($form, $object) {
        $form->model->default_values($object);
    }

    method delete_many ($ctx, $rows) {
        $rows->delete;
        $ctx->response->redirect( $ctx->uri_for($self->action_for('list')) );
    }

    chain base () {
        $ctx->stash(collection => $self->get_collection($ctx))
            unless $ctx->stash->{collection};
    }

    chain search at '/' () {
        $ctx->stash(collection => $ctx->stash->{collection}->search_fields(
            $self->search_fields, $ctx->request->param('q'),
        ));
    }

    under search, chain page at '/' () {
        my $page = $ctx->request->param('page') // 1;
        my $rows = $ctx->request->parma('rows') // 20;

        my $collection = $ctx->stash->{collection}->search_rs(undef, {
            page => $page, rows => $rows,
        });

        $ctx->stash(
            collection => $collection,
            pager      => $collection->pager,
            pager_uri  => sub { $ctx->request->uri_with({ page => $_[0] }) },
        );
    }

    under page, action list at '/' () {
        $ctx->stash(
            list_actions => $self->list_actions,
            row_actions  => [
                map {
                    my $action = $_;
                    { name => $action, uri_for => sub { $ctx->uri_for($self->action_for($action), [@_]) } }
                } @{ $self->row_actions }
            ],
        );
    }

    action create with(FormConfig) () {
        return unless $ctx->request->method eq 'POST';
        my $form = $ctx->stash->{form};
        return unless $form->submitted_and_valid;

        $self->create_row($form);
        $ctx->response->redirect( $ctx->uri_for($self->action_for('list')) );
    }

    action object at '/id' (Int $id) {
        $ctx->stash(object => $ctx->stash->{collection}->find($args[0]));
        $ctx->detach('/error_404') unless $ctx->stash->{object};
    }

    under object {
        action view () {}

        action edit with(FormConfig) () {
            my $form = $ctx->stash->{form};
            $self->defaults_from_row($form, $ctx->stash->{object});

            return unless $ctx->request->method eq 'POST';
            return unless $form->submitted_and_valid;

            self->update_row($form, $ctx->stash->{object});
            $ctx->response->redirect( $ctx->uri_for($self->action_for('list')) );
        }

        action delete () {
            $ctx->stash->{object}->delete;
            $ctx->response->redirect( $ctx->uri_for($self->action_for('list')) );
        }
    }

    action list_action () {
        for my $action (@{ $self->list_actions }) {
            next unless exists $ctx->request->params->{ $action->{name} };
            my $rows = $ctx->stash->{collection}->search_by_ids($ctx->request->param('select_many'));
            my $method = $action->{'method'} // $action->{name};
            $ctx->detach('/error_404') unless $self->can($method);
            $self->$method($ctx, $rows);
            return;
        }
    }
}

1;
