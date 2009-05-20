package Net::Parliament::Member;
use Moose;
use namespace::clean -except => 'meta';

has 'member_name'       => (is => 'ro', isa => 'Str');
has 'caucus'            => (is => 'ro', isa => 'Str');
has 'constituency'      => (is => 'ro', isa => 'Str');
has 'province'          => (is => 'ro', isa => 'Str');

has 'email'             => (is => 'ro', isa => 'Str');
has 'web site'          => (is => 'ro', isa => 'Str');
has 'telephone'         => (is => 'ro', isa => 'Str');
has 'fax'               => (is => 'ro', isa => 'Str');
has 'profile_photo_url' => (is => 'ro', isa => 'Str');
has 'member_url'        => (is => 'ro', isa => 'Str');

__PACKAGE__->meta->make_immutable;

1;
