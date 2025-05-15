# pgvector-perl

[pgvector](https://github.com/pgvector/pgvector) examples for Perl

Supports [DBD::Pg](https://github.com/bucardo/dbdpg)

[![Build Status](https://github.com/pgvector/pgvector-perl/actions/workflows/build.yml/badge.svg)](https://github.com/pgvector/pgvector-perl/actions)

## Getting Started

Follow the instructions for your database library:

- [DBD::Pg](#dbdpg)

Or check out some examples:

- [Embeddings](examples/openai/example.pl) with OpenAI
- [Binary embeddings](examples/cohere/example.pl) with Cohere
- [Hybrid search](examples/hybrid/example.pl) with Ollama (Reciprocal Rank Fusion)
- [Sparse search](examples/sparse/example.pl) with Text Embeddings Inference

## DBD::Pg

Enable the extension

```perl
$dbh->do('CREATE EXTENSION IF NOT EXISTS vector');
```

Create a table

```perl
$dbh->do('CREATE TABLE items (id bigserial PRIMARY KEY, embedding vector(3))');
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
    print($row[1] . "\n");
}
```

Add an approximate index

```perl
$dbh->do('CREATE INDEX ON items USING hnsw (embedding vector_l2_ops)');
# or
$dbh->do('CREATE INDEX ON items USING ivfflat (embedding vector_l2_ops) WITH (lists = 100)');
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

To run an example:

```sh
cd examples/openai
createdb pgvector_example
perl example.pl
```
