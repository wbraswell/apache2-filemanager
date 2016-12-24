# [[[ PREPROCESSOR ]]]
# <<< TYPE_CHECKING: OFF >>>

# [[[ HEADER ]]]
package Apache2::FileManager::PSGI;
use strict;
use warnings;
#use RPerl::AfterSubclass;
our $VERSION = 0.001_000;

BEGIN {
    for (
        qw/Log Util Const Request RequestIO RequestRec RequestUtil ServerUtil Upload/
        )
    {
        $INC{ 'Apache2/' . $_ . '.pm' } = '1';
    }
}

package Apache2::Const {
    use constant {
        DECLINED => -1,
        OK       => 200,
    };
}

package Apache2::Request;
sub new { }

package Apache2::Util;

sub escape_path { return "" . $_[0] }

package Apache2::FileManager::PSGI;

use Moose;

has 'document_root' => ( is => 'ro', required => 1, isa => 'Str' );
has 'request' => ( is => 'ro', required => 1, handles => [qw/param uri/] );
has 'status' => ( is => 'rw', default => 200 );
has 'response' => ( is => 'ro', lazy_build => 1, handles => [qw/content_type/] );
has 'dir_config_var' => ( is => 'rw', required => 1 );

sub new_from_psgi {
#    print {*STDERR} 'in PSGI::new_from_psgi(), have @_ = ', Dumper(\@_), "\n\n";
    my $env = shift;
    my $document_root = shift;
#    print {*STDERR} 'in PSGI::new_from_psgi(), have $env = ', q{'}, $env, q{'}, "\n";
#    print {*STDERR} 'in PSGI::new_from_psgi(), have $document_root = ', q{'}, $document_root, q{'}, "\n";
    my $request = Plack::Request->new($env);

    my $request_wrapped_psgi = Apache2::FileManager::PSGI->new(
        {   request       => $request,
            document_root => $document_root,
            dir_config_var        => {}
#            dir_config_var        => { DOCUMENT_ROOT => '/tmp/FOO'}  # DEV NOTE: example usage of dir_config_var override, should not be needed in PSGI?
        }
    );

    return $request_wrapped_psgi;
}

sub pool { }

sub upload {
    my ( $self, $param ) = @_;
    my $plack_request_upload = $self->request->uploads->{$param};
    return $plack_request_upload;
}

sub log_error {
    my $self = shift;
    warn shift;
}

sub headers_in {
    my $self = shift;
    return { Cookie => $self->request->headers->{'cookie'} };
}

sub hostname {
    my $self = shift;
    return $self->request->base->host;
}

sub _build_response {
    my $self = shift;
    $self->request->new_response( $self->status );
}

sub dir_config {
    my ( $self, $key ) = @_;
    return $self->{dir_config_var}->{$key};
}

my $charset
    = '<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />';

sub print {
    my ( $self, $content ) = @_;
    my $body = $self->response->body // '';
    my $all = $body . $content;
    ( $all =~ s!(\<HTML\>\<HEAD\>)!$1$charset! )
        || ( $all =~ s!(\<HTML\>)!$1<HEAD>$charset</HEAD>! )
        || warn "Unable to add encoding";
    $self->response->body($all);
    return 1;
}

1;
