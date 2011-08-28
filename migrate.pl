#!/usr/bin/env perl
# vim:ts=4:sw=4:expandtab

use strict;
use warnings;
use Data::Dumper;
use AnyEvent;
use AnyEvent::CouchDB;
use v5.10;
use utf8;
#use Encode qw(decode_utf8);

binmode STDOUT, ":utf8";

my $couch = couch();
my $db = $couch->db('blog');
my $cv = $db->all_docs;
my $all = $cv->recv;
my @docs = grep { /^[0-9]+$/ } map { $_->{id} } @{$all->{rows}};

@docs = sort { $a <=> $b } @docs;

for my $id (@docs) {
    $cv = $db->open_doc($id);
    my $doc = $cv->recv;
    my $text = $doc->{text};
    my ($date) = ($doc->{posted} =~ m,^([0-9]{4}/[0-9]{2}/[0-9]{2}),);
    $date =~ s,/,-,g;
    my $time = $doc->{posted};
    my $title = $text;
    $title =~ s/<[^>]+>//ig;
    $title = substr($title, 0, 30) . "…";

    my $url = $title;
    $url =~ s/ /-/g;
    $url =~ s/[^a-zA-Z0-9-]//g;

    open(my $fh, '>:utf8', "_posts/$date-$url.html");
    say $fh "---";
    say $fh "permalink: /post/$id";
    say $fh "layout: post";
    say $fh qq|date: $time|;
    say $fh qq|title: "$title"|;
    say $fh "---";
    say $fh $text;
    close($fh);
}
