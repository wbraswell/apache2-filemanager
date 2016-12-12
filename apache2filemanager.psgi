package Plack::App::Apache2FileManager;

use strict;
use warnings;

use Plack::Request;
use Plack::App::Apache2FileManager::Mocks;
use Apache2::FileManager;
use Plack::Builder;

my $document_root = '/tmp';

our $R;
our $CONFIG;

undef *Apache2::FileManager::r;
*Apache2::FileManager::r = sub { return $R };

my $app = sub {
    my $env = shift;
    my $req = Plack::Request->new($env);

    local $R = Plack::App::Apache2FileManager::Mocks->new(
        {   request       => $req,
            document_root => $document_root
        }
    );
    local $CONFIG = {};

    # DEV NOTE: r->print() is     called in handler()         and calls therefrom, returns Apache2::Const::OK
#    Apache2::FileManager->handler();

    # DEV NOTE: r->print() is not called in handler_noprint() or  calls therefrom, returns generated HTML
    my $handler_retval = Apache2::FileManager->handler_noprint();
    $R->print($handler_retval);

    return $R->response->finalize;
};

builder {
    enable "Plack::Middleware::Static",
        path => qr{^/.+},
        root => $document_root;
    $app;
}
