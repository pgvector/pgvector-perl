use strict;
use DBI;
use HTTP::Tiny;
use JSON::PP;

my $dbh = DBI->connect('dbi:Pg:dbname=pgvector_example', '', '', {AutoCommit => 1});

$dbh->do('CREATE EXTENSION IF NOT EXISTS vector');
$dbh->do('DROP TABLE IF EXISTS documents');
$dbh->do('CREATE TABLE documents (id bigserial PRIMARY KEY, content text, embedding vector(768))');
$dbh->do("CREATE INDEX ON documents USING GIN (to_tsvector('english', content))");

sub vector {
    return '[' . join(',', @{$_[0]}) . ']';
}

sub embed {
    my ($input, $task_type) = @_;

    # nomic-embed-text uses a task prefix
    # https://huggingface.co/nomic-ai/nomic-embed-text-v1.5
    my @input = map { $task_type . ': ' . $_ } @$input;

    my $url = 'http://localhost:11434/api/embed';
    my %data = (
        'input' => \@input,
        'model' => 'nomic-embed-text'
    );
    my %headers = (
        'Content-Type' => 'application/json'
    );

    my $response = HTTP::Tiny->new->post($url, {content => encode_json(\%data), headers => \%headers});
    return @{decode_json($response->{content})->{embeddings}};
}

my @documents = (
    'The dog is barking',
    'The cat is purring',
    'The bear is growling'
);
my @embeddings = embed(\@documents, 'search_document');
my $sth = $dbh->prepare('INSERT INTO documents (content, embedding) VALUES ($1, $2)');
for my $i (0 .. $#documents) {
    $sth->execute($documents[$i], vector($embeddings[$i]));
}

my $sql = <<SQL;
WITH semantic_search AS (
    SELECT id, RANK () OVER (ORDER BY embedding <=> \$2) AS rank
    FROM documents
    ORDER BY embedding <=> \$2
    LIMIT 20
),
keyword_search AS (
    SELECT id, RANK () OVER (ORDER BY ts_rank_cd(to_tsvector('english', content), query) DESC)
    FROM documents, plainto_tsquery('english', \$1) query
    WHERE to_tsvector('english', content) @@ query
    ORDER BY ts_rank_cd(to_tsvector('english', content), query) DESC
    LIMIT 20
)
SELECT
    COALESCE(semantic_search.id, keyword_search.id) AS id,
    COALESCE(1.0 / (\$3 + semantic_search.rank), 0.0) +
    COALESCE(1.0 / (\$3 + keyword_search.rank), 0.0) AS score
FROM semantic_search
FULL OUTER JOIN keyword_search ON semantic_search.id = keyword_search.id
ORDER BY score DESC
LIMIT 5
SQL
my $query = 'growling bear';
my ($embedding) = embed([$query], 'search_query');
my $k = 60;
my $sth = $dbh->prepare($sql);
$sth->execute($query, vector($embedding), $k);
while (my @row = $sth->fetchrow_array()) {
    print('document: ' . $row[0] . ', RRF score: ' . $row[1] . "\n");
}
