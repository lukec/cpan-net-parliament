package Net::Parliament::UserAgent;
use Moose;
extends 'LWP::UserAgent';
use IO::All;
use Digest::MD5 qw/md5_hex/;
use File::Path qw/mkpath/;
use Fatal qw/mkpath/;

has 'cache_dir' => (is => 'ro', isa => 'Str', lazy_build => 1);

sub _build_cache_dir {
	my $self = shift;
	my $dir = "cache";

	if (!-d $dir) {
		mkpath($dir);
	}
	return $dir;
}

around 'get' => sub {
	my $orig = shift;
	my $self = shift;
    my $url = shift;

	my $file = $self->_url_to_file($url);
	if (-e $file) {
		print "Returning $url from $file\n";
		return io($file)->all();
	}

	my $resp = $orig->($self, $url);
	my $html = $resp->content;
	io($file)->print($html);
	print "Saved $url to $file\n";

	return $html;
};

sub _url_to_file { 
	my $self = shift;
	my $cd = $self->cache_dir;
	return join '/', $cd, md5_hex(shift);
}

1;
