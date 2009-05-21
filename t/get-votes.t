#!/usr/bin/perl
use strict;
use warnings;
use Test::More qw/no_plan/;

use_ok 'Net::Parliament';

my $np = Net::Parliament->new();
isa_ok $np, 'Net::Parliament';

my $votes = $np->Get_bill_votes( parl => 39, session => 2, bill => 'C-2');
my $vote = shift @$votes;
is_deeply $vote, {
    'TotalNays' => '1',
    'number' => '15',
    'parliament' => '39',
    'TotalYeas' => '221',
    'Decision' => 'Agreed to',
    'date' => '2007-11-26',
    'TotalPaired' => '0',
    'session' => '2',
    'RelatedBill' => {
        'number' => 'C-2'
    },
    'sitting' => '24'
};

