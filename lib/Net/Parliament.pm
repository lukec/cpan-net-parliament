package Net::Parliament;
use Moose;
use MooseX::AttributeInflate;
use XML::Simple;
use Net::Parliament::UserAgent;
use HTML::TableExtract qw/tree/;

has '_members_base_url' => (
    is => 'ro',
    isa => 'Str',
    default => 'http://webinfo.parl.gc.ca/MembersOfParliament/',
);

has 'members_html_url' => (
	is => 'ro',
	isa => 'Str',
	default => sub { shift->_members_base_url . 'MainMPsCompleteList.aspx?TimePeriod=Current' },
);

has_inflated 'ua' => (
	is => 'ro',
	isa => 'Net::Parliament::UserAgent',
	handles => ['get'],
);

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
        push @members, $member;
    }

    return \@members;
}

sub Load_member {
    my $self = shift;
    my $member = shift;
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
    my $self = shift;
    my $content = shift;

    my $te = HTML::TableExtract->new( depth => 3, count => 1);
    $te->parse($content);

    my ($member_table) = $te->tables;
    my $row = $member_table->tree->row(1);
    my ($profile_img) = $row->look_down('_tag', 'img');
    return $self->_members_base_url . $profile_img->attr('src');
}

sub _extract_more_details {
    my $self = shift;
    my $content = shift;
    my $member = shift;

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

1;
