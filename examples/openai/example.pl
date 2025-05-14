use strict;
use DBI;
use HTTP::Tiny;
use JSON::PP;

my $dbh = DBI->connect('dbi:Pg:dbname=pgvector_example', '', '', {AutoCommit => 1});

$dbh->do('CREATE EXTENSION IF NOT EXISTS vector');
$dbh->do('DROP TABLE IF EXISTS documents');
$dbh->do('CREATE TABLE documents (id bigserial PRIMARY KEY, content text, embedding vector(1536))');

sub vector {
    return '[' . join(',', @{$_[0]}) . ']';
}

sub embed {
    my $api_key = $ENV{OPENAI_API_KEY};
    my $url = 'https://api.openai.com/v1/embeddings';
    my %data = (
        'input' => @_[0],
        'model' => 'text-embedding-3-small'
    );
    my %headers = (
        'Authorization' => 'Bearer ' . $api_key,
        'Content-Type' => 'application/json'
    );

    my $response = HTTP::Tiny->new->post($url, {content => encode_json(\%data), headers => \%headers});
    return map {$_->{embedding}} @{decode_json($response->{content})->{data}};
}

my @documents = (
    'The dog is barking',
    'The cat is purring',
    'The bear is growling'
);
my @embeddings = embed(\@documents);
my $sth = $dbh->prepare('INSERT INTO documents (content, embedding) VALUES ($1, $2)');
for my $i (0 .. $#documents) {
    $sth->execute($documents[$i], vector($embeddings[$i]));
}

my $query = 'forest';
my @embedding = embed([$query]);
my $sth = $dbh->prepare('SELECT content FROM documents ORDER BY embedding <=> $1 LIMIT 5');
$sth->execute(vector($embedding[0]));
while (my @row = $sth->fetchrow_array()) {
    print($row[0] . "\n");
}
