use strict;
use warnings;

use Plack::Request;
use Plack::Builder;
use Apache2::FileManager::PSGI;
use Apache2::FileManager;
#use Data::Dumper;

# local variables
my $document_root = '/tmp';
my $request_wrapped_psgi;

# override $r with $request_wrapped_psgi, thereby wrapping $r
undef *Apache2::FileManager::r;
*Apache2::FileManager::r = sub { return $request_wrapped_psgi };

# create new $request_wrapped_psgi, generate HTML
my $app = sub {
    my $env = shift;
    $request_wrapped_psgi = Apache2::FileManager::PSGI::new_from_psgi($env, $document_root);
#    print {*STDERR} 'in $app(), have $request_wrapped_psgi = ', Dumper($request_wrapped_psgi), "\n\n";

    # DEV NOTE: r->print() is     called in handler()         and calls therefrom, returns Apache2::Const::OK
#    Apache2::FileManager->handler();

    # DEV NOTE: r->print() is not called in handler_noprint() or  calls therefrom, returns generated HTML
    my $handler_retval = Apache2::FileManager->handler_noprint();
    $request_wrapped_psgi->print($handler_retval);

    return $request_wrapped_psgi->response->finalize;
};

# enable static files
builder {
    enable "Plack::Middleware::Static",
        path => qr{^/.+},
        root => $document_root;
    $app;
}
