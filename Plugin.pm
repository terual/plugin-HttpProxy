package Plugins::HttpProxy::Plugin;

use base qw(Slim::Plugin::Base);

use strict;

use URI::Escape qw(uri_unescape);
use File::Temp qw(tempfile);

use Slim::Networking::SimpleSyncHTTP;
use Slim::Utils::Log;
use Data::Dumper; 

my $log = Slim::Utils::Log->addLogCategory({
	'category'     => 'plugin.HttpProxy',
	'defaultLevel' => 'DEBUG',
	'description'  => 'PLUGIN_HTTPPROXY',
});

sub initPlugin {
	my $class = shift;

	$class->SUPER::initPlugin();
}

sub webPages {
	
	Slim::Web::Pages->addRawFunction("plugins/httpproxy", \&handleHttpProxy);

}

sub handleHttpProxy {
	my ($httpClient, $response, $func) = @_;

	my $url = $response->{'_request'}->{'_uri'};
	$url =~ s/\/plugins\/httpproxy\?//;
	
	$url =~ m|([^/]+)/?$|;
	my $filename = $1;
		
 	$log->info("Got request for $url");
 	
 	# It is reasonable to block here. Async wouldn't work because this callback has to return the data
 	my $http = Slim::Networking::SimpleSyncHTTP->new();
	$http->get($url);
	
	if ($http->is_success) {

		$log->info("Reponse for $url sucess");

		my $contentRef = $http->contentRef;
		
		$response->header( 'Content-Length' => length($$contentRef) );
		$response->code(200);
		$response->header('Connection' => 'close');
		$response->content_type('application/octet-stream');
		$response->header( 'Content-Disposition' => 'inline; filename="' . $filename . '"' );
		
		Slim::Web::HTTP::addHTTPResponse( $httpClient, $response, $contentRef );

	}
}


1;
