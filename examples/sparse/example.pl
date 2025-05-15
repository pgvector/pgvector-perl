use strict;
use DBI;
use HTTP::Tiny;
use JSON::PP;

my $dbh = DBI->connect('dbi:Pg:dbname=pgvector_example', '', '', {AutoCommit => 1});

$dbh->do('CREATE EXTENSION IF NOT EXISTS vector');
$dbh->do('DROP TABLE IF EXISTS documents');
$dbh->do('CREATE TABLE documents (id bigserial PRIMARY KEY, content text, embedding sparsevec(30522))');

sub sparsevec {
    my ($elements, $dim) = @_;
    return '{' . join(',', map { $_->{index} . ':' . $_->{value} } @$elements) . '}/' . $dim;
}

sub embed {
    my $url = 'http://localhost:3000/embed_sparse';
    my %data = (
        'inputs' => @_[0]
    );
    my %headers = (
        'Content-Type' => 'application/json'
    );

    my $response = HTTP::Tiny->new->post($url, {content => encode_json(\%data), headers => \%headers});
    return @{decode_json($response->{content})};
}

my @documents = (
    'The dog is barking',
    'The cat is purring',
    'The bear is growling'
);
my @embeddings = embed(\@documents);
my $sth = $dbh->prepare('INSERT INTO documents (content, embedding) VALUES ($1, $2)');
for my $i (0 .. $#documents) {
    $sth->execute($documents[$i], sparsevec($embeddings[$i], 30522));
}

my $query = 'forest';
my ($embedding) = embed([$query]);
my $sth = $dbh->prepare('SELECT content FROM documents ORDER BY embedding <#> $1 LIMIT 5');
$sth->execute(sparsevec($embedding, 30522));
while (my @row = $sth->fetchrow_array()) {
    print($row[0] . "\n");
}
