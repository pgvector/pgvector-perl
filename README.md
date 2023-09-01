# pgvector-perl

[pgvector](https://github.com/pgvector/pgvector) examples for Perl

Supports [DBD::Pg](https://github.com/bucardo/dbdpg)

[![Build Status](https://github.com/pgvector/pgvector-perl/workflows/build/badge.svg?branch=master)](https://github.com/pgvector/pgvector-perl/actions)

## Getting Started

Follow the instructions for your database library:

- [DBD::Pg](#dbdpg)

## DBD::Pg

Create a table

```perl
$dbh->do('CREATE TABLE items (embedding vector(3))');
```

Insert vectors

```perl
sub vector {
    return '[' . join(',', @{$_[0]}) . ']';
}

my $sth = $dbh->prepare('INSERT INTO items (embedding) VALUES ($1), ($2), ($3)');
my @embedding1 = (1, 1, 1);
my @embedding2 = (2, 2, 2);
my @embedding3 = (1, 1, 2);
$sth->execute(vector(\@embedding1), vector(\@embedding2), vector(\@embedding3));
```

Get the nearest neighbors

```perl
my $sth = $dbh->prepare('SELECT * FROM items ORDER BY embedding <-> $1 LIMIT 5');
my @embedding = (1, 1, 1);
$sth->execute(vector(\@embedding));
while (my @row = $sth->fetchrow_array()) {
    print($row[0] . "\n");
}
```

Add an approximate index

```perl
$dbh->do('CREATE INDEX my_index ON items USING ivfflat (embedding vector_l2_ops)');
# or
$dbh->do('CREATE INDEX my_index ON items USING hnsw (embedding vector_l2_ops)');
```

Use `vector_ip_ops` for inner product and `vector_cosine_ops` for cosine distance

See a [full example](example.pl)

## Contributing

Everyone is encouraged to help improve this project. Here are a few ways you can help:

- [Report bugs](https://github.com/pgvector/pgvector-perl/issues)
- Fix bugs and [submit pull requests](https://github.com/pgvector/pgvector-perl/pulls)
- Write, clarify, or fix documentation
- Suggest or add new features

To get started with development:

```sh
git clone https://github.com/pgvector/pgvector-perl.git
cd pgvector-perl
createdb pgvector_perl_test
cpan DBD::Pg
perl example.pl
```
