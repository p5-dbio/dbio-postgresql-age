---
name: dbio-postgresql-age-graph
description: Use when working with PostgreSQL AGE graph operations through DBIO::PostgreSQL::Age, especially graph creation, vertices/nodes, edges/relationships, Cypher queries, cypher() integration, and agtype results.
---

# DBIO PostgreSQL AGE Graph Quick Reference

Use this skill for practical Apache AGE graph database work with `DBIO::PostgreSQL::Age`.

## Setup

Load the AGE component on your schema and use the `load_age` connection callback so each PostgreSQL session runs `LOAD 'age'` and sets `ag_catalog` in the search path.

```perl
package MyApp::Schema;
use base 'DBIO::Schema';

__PACKAGE__->load_components('PostgreSQL::Age');

my $schema = MyApp::Schema->connect(
  $dsn,
  $user,
  $pass,
  {
    AutoCommit      => 1,
    RaiseError      => 1,
    PrintError      => 0,
    on_connect_call => 'load_age',
  },
);

my $storage = $schema->storage;
```

If the database may not already have AGE installed:

```perl
$storage->dbh->do('CREATE EXTENSION IF NOT EXISTS age');
```

## Graph Lifecycle

Create a graph before inserting vertices or edges.

```perl
$storage->create_graph('social');
```

Drop a graph when done. Use cascade for non-empty graphs.

```perl
$storage->drop_graph('social', 1);
```

Graph names are validated by `cypher()` as plain PostgreSQL-style identifiers:

```
valid:   social, app_graph_1
invalid: app-graph, public.social, graph name
```

## Running Cypher

Use:

```perl
my $rows = $storage->cypher(
  $graph_name,
  $cypher_query,
  \@result_columns,
  \%optional_params,
);
```

Every result column is declared as `agtype`. The return value is an arrayref of hashrefs.

```perl
my $rows = $storage->cypher(
  'social',
  q{ MATCH (p:Person) RETURN p.name, p.age },
  [qw(name age)],
);

for my $row (@$rows) {
  say "$row->{name} is $row->{age}";
}
```

## Creating Vertices

AGE requires `cypher()` queries to return at least one declared column, so `CREATE` examples usually return a simple value.

```perl
$storage->cypher(
  'social',
  q{
    CREATE (:Person {name: 'Alice', age: 30}),
           (:Person {name: 'Bob',   age: 25})
    RETURN 1
  },
  ['ok'],
);
```

Prefer parameters for dynamic values.

```perl
$storage->cypher(
  'social',
  q{
    CREATE (:Person {name: $name, age: $age})
    RETURN 1
  },
  ['ok'],
  {
    name => 'Carol',
    age  => 28,
  },
);
```

## Creating Edges

Match existing vertices, then create the relationship.

```perl
$storage->cypher(
  'social',
  q{
    MATCH (a:Person {name: $from}), (b:Person {name: $to})
    CREATE (a)-[:KNOWS {since: $since}]->(b)
    RETURN 1
  },
  ['ok'],
  {
    from  => 'Alice',
    to    => 'Bob',
    since => 2020,
  },
);
```

Create multiple vertices and edges in one query when useful.

```perl
$storage->cypher(
  'social',
  q{
    CREATE (alice:Person {name: 'Alice'}),
           (bob:Person   {name: 'Bob'}),
           (alice)-[:KNOWS {since: 2020}]->(bob)
    RETURN 1
  },
  ['ok'],
);
```

## Querying Relationships

```perl
my $rows = $storage->cypher(
  'social',
  q{
    MATCH (a:Person)-[r:KNOWS]->(b:Person)
    RETURN a.name, b.name, r.since
  },
  [qw(person friend since)],
);

for my $row (@$rows) {
  say "$row->{person} knows $row->{friend} since $row->{since}";
}
```

## Working With agtype Results

`cypher()` returns AGE `agtype` values as strings through DBI. Scalars often come back as AGE text representations.

Common scalar cleanup:

```perl
sub ag_string {
  my ($value) = @_;
  return undef unless defined $value;
  $value =~ s/\A"//;
  $value =~ s/"\z//;
  return $value;
}

my $rows = $storage->cypher(
  'social',
  q{ MATCH (p:Person) RETURN p.name },
  ['name'],
);

my @names = map { ag_string($_->{name}) } @$rows;
```

For JSON-like agtype values, use `JSON::MaybeXS` when the returned value is valid JSON.

```perl
use JSON::MaybeXS qw(decode_json);

my $rows = $storage->cypher(
  'social',
  q{ MATCH (p:Person {name: $name}) RETURN p {.name, .age} },
  ['person'],
  { name => 'Alice' },
);

my $person = decode_json($rows->[0]{person});
say $person->{name};
```

For full vertices, edges, and paths, AGE may include graph type annotations in the textual representation. Prefer returning specific properties or projected maps when application code needs structured values.

```perl
my $rows = $storage->cypher(
  'social',
  q{
    MATCH (a:Person)-[r:KNOWS]->(b:Person)
    RETURN {
      from: a.name,
      to: b.name,
      since: r.since
    }
  },
  ['relationship'],
);
```

## Practical Pattern

Use this shape for most application operations:

```perl
sub friends_of {
  my ($schema, $name) = @_;

  my $rows = $schema->storage->cypher(
    'social',
    q{
      MATCH (:Person {name: $name})-[:KNOWS]->(friend:Person)
      RETURN friend.name
      ORDER BY friend.name
    },
    ['friend'],
    { name => $name },
  );

  return [ map { ag_string($_->{friend}) } @$rows ];
}
```

## Checklist

- Load `PostgreSQL::Age` on the schema.
- Connect with `{ on_connect_call => 'load_age' }`.
- Ensure `CREATE EXTENSION IF NOT EXISTS age` has run for the database.
- Create the graph with `$storage->create_graph($name)`.
- Use `$storage->cypher($graph, $query, \@columns, \%params)` for Cypher.
- Always provide result column names matching the `RETURN` expressions.
- Prefer parameters over interpolating user values into Cypher.
- Return properties or projected maps when easier agtype parsing is needed.
- Drop test graphs with `$storage->drop_graph($name, 1)`.
