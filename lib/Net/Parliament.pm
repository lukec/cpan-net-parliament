package Net::Parliament;
use Moose;
use Net::Parliament::UserAgent;
use HTML::TableExtract qw/tree/;

=head1 NAME

Net::Parliament - Scrape data from parl.gc.ca

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

This module will fetch HTML and XML from parl.gc.ca,
and then parse it into hashrefs.

    use Net::Parliament;

    my $members = Net::Parliament->Get_members();
    for my $member (@$members) {
        ...
    }

=cut

has '_members_base_url' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'http://webinfo.parl.gc.ca/MembersOfParliament/',
);

has 'members_html_url' => (
    is      => 'ro',
    isa     => 'Str',
    default => sub {
        shift->_members_base_url
            . 'MainMPsCompleteList.aspx?TimePeriod=Current';
    },
);

has 'ua' => (
    is      => 'ro',
    isa     => 'Net::Parliament::UserAgent',
    handles => ['get'],
    default => sub { Net::Parliament::UserAgent->new },
);

=head1 CLASS METHODS

=head2 Get_members()

This method returns an arrayref containing a hashref for each
member of parliament.  Fetching the data is cached via
Net::Parliament::UserAgent.

=cut

sub Get_members {
    my $self = shift;

    my $members_page = $self->get($self->members_html_url);

    my $te = HTML::TableExtract->new( 
        headers => [ 'Member of Parliament', 'Constituency', 
                     'Province/Territory', 'Caucus' ],
    );
    $te->parse($members_page);

    my ($member_table) = $te->tables;
    my $table_tree = $member_table->tree;

    my @members;
    for my $i (1 .. $table_tree->maxrow) {
        my $row = $table_tree->row($i);
        my @cols =$row->look_down('_tag', 'td');

        my $member = {};
        eval {
            $member->{member_url}
                = $self->_members_base_url
                . $cols[0]->find_by_tag_name('a')->attr('href');
            $member->{member_name}
                = $cols[0]->find_by_tag_name('a')->content->[0];
            $member->{constituency}
                = $cols[1]->find_by_tag_name('a')->content->[0];
            $member->{province} = $cols[2]->content->[0];
            $member->{caucus}   = $cols[3]->content->[0];
            if (ref($member->{caucus})) {
                $member->{caucus} = $member->{caucus}->content->[0];
            }
        };
        if ($@) {
            warn "Error parsing row: $@";
            $row->dump;
        }
        push @members, $self->_load_member($member);
    }

    return \@members;
}

sub _load_member {
    my $self       = shift;
    my $member     = shift;
    my $member_url = $member->{member_url};

    my $content = $self->get($member_url);
    eval {
        $member->{profile_photo_url} = $self->_extract_photo_url($content);
        $self->_extract_more_details($content, $member);
    };
    if ($@) {
        die "Couldn't extract details from $member_url\n";
    }

    return $member;
}

sub _extract_photo_url {
    my $self    = shift;
    my $content = shift;

    my $te = HTML::TableExtract->new( depth => 3, count => 1);
    $te->parse($content);

    my ($member_table) = $te->tables;
    my $row            = $member_table->tree->row(1);
    my ($profile_img)  = $row->look_down('_tag', 'img');
    return $self->_members_base_url . $profile_img->attr('src');
}

sub _extract_more_details {
    my $self    = shift;
    my $content = shift;
    my $member  = shift;

    my $te = HTML::TableExtract->new( depth => 5, count => 6);
    $te->parse($content);

    my ($details) = $te->tables;
    my $tree = $details->tree;

    for my $row (map { $tree->row($_) } 5 .. 8) {
        eval {
            my ($key, $val)
                = map { $_->content->[0]->content->[0] }
                $row->look_down('_tag', 'td');

            $key =~ s/:\*?$//;
            $key = lc($key);

            if ($key eq 'web site') {
                $val = 'http://' . $val;
            }

            $member->{$key} = $val;
        };
    }
}

=head1 AUTHOR

Luke Closs, C<< <cpan at 5thplane.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-parliament at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Parliament>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Parliament

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-Parliament>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-Parliament>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-Parliament>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-Parliament/>

=back

=head1 ACKNOWLEDGEMENTS

Thanks to parl.gc.ca for the parts of their site in XML format.

=head1 COPYRIGHT & LICENSE

Copyright 2009 Luke Closs, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
