use DBI;

my $dbh = DBI->connect('dbi:Pg:dbname=pgvector_perl_test', '', '', {AutoCommit => 1});

$dbh->do('CREATE EXTENSION IF NOT EXISTS vector');
$dbh->do('DROP TABLE IF EXISTS items');
$dbh->do('CREATE TABLE items (embedding vector(3))');

sub vector {
    return '[' . join(',', @{$_[0]}) . ']';
}

my $sth = $dbh->prepare('INSERT INTO items (embedding) VALUES ($1), ($2), ($3)');
my @embedding1 = (1, 1, 1);
my @embedding2 = (2, 2, 2);
my @embedding3 = (1, 1, 2);
$sth->execute(vector(\@embedding1), vector(\@embedding2), vector(\@embedding3));

my $sth = $dbh->prepare('SELECT * FROM items ORDER BY embedding <-> $1 LIMIT 5');
my @embedding = (1, 1, 1);
$sth->execute(vector(\@embedding));
while (my @row = $sth->fetchrow_array()) {
    print($row[0] . "\n");
}

$dbh->do('CREATE INDEX my_index ON items USING ivfflat (embedding vector_l2_ops)');
