use strict;
use DBI;
use HTTP::Tiny;
use JSON::PP;

my $dbh = DBI->connect('dbi:Pg:dbname=pgvector_example', '', '', {AutoCommit => 1});

$dbh->do('CREATE EXTENSION IF NOT EXISTS vector');
$dbh->do('DROP TABLE IF EXISTS documents');
$dbh->do('CREATE TABLE documents (id bigserial PRIMARY KEY, content text, embedding bit(1536))');

sub embed {
    my ($texts, $input_type) = @_;

    my $api_key = $ENV{CO_API_KEY};
    my $url = 'https://api.cohere.com/v2/embed';
    my %data = (
        'texts' => $texts,
        'model' => 'embed-v4.0',
        'input_type' => $input_type,
        'embedding_types' => ['ubinary']
    );
    my %headers = (
        'Authorization' => 'Bearer ' . $api_key,
        'Content-Type' => 'application/json'
    );

    my $response = HTTP::Tiny->new->post($url, {content => encode_json(\%data), headers => \%headers});
    return map {join('', map {sprintf('%08b', $_)} @{$_})} @{decode_json($response->{content})->{embeddings}->{ubinary}};
}

my @documents = (
    'The dog is barking',
    'The cat is purring',
    'The bear is growling'
);
my @embeddings = embed(\@documents, 'search_document');
my $sth = $dbh->prepare('INSERT INTO documents (content, embedding) VALUES ($1, $2)');
for my $i (0 .. $#documents) {
    $sth->execute($documents[$i], $embeddings[$i]);
}

my $query = 'forest';
my @embedding = embed([$query], 'search_query');
my $sth = $dbh->prepare('SELECT content FROM documents ORDER BY embedding <~> $1 LIMIT 5');
$sth->execute($embedding[0]);
while (my @row = $sth->fetchrow_array()) {
    print($row[0] . "\n");
}
