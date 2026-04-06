package DBIO::PostgreSQL::Age::Storage;
# ABSTRACT: PostgreSQL storage with Apache AGE graph support
our $VERSION = '0.900000';

use strict;
use warnings;

use base 'DBIO::PostgreSQL::Storage';

=head1 SYNOPSIS

  # Loaded automatically via DBIO::PostgreSQL::Age component.
  # Use connect_call_load_age to initialize AGE on each connection:

  MyApp::Schema->connect(
    $dsn, $user, $pass,
    { on_connect_call => 'load_age' },
  );

  my $storage = $schema->storage;

  $storage->create_graph('social');

  my $rows = $storage->cypher(
    'social',
    $$ MATCH (a:Person {name: $name})-[:KNOWS]->(b) RETURN b.name $$,
    ['friend'],
    { name => 'Alice' },
  );

  $storage->drop_graph('social', 1);  # cascade

=head1 DESCRIPTION

Extends L<DBIO::PostgreSQL::Storage> with Apache AGE graph database support.
Provides connection initialization, graph lifecycle management, and Cypher
query execution.

All result columns from C<cypher()> are declared as C<agtype> — Apache AGE's
JSON-superset type that represents vertices, edges, paths, and scalar values.
Values are returned as strings and can be decoded with a JSON parser.

=cut

sub connect_call_load_age {
  my $self = shift;
  $self->_do_query(q{LOAD 'age'});
  $self->_do_query(q{SET search_path = ag_catalog, "$user", public});
}

=method connect_call_load_age

  { on_connect_call => 'load_age' }

Connection callback that loads the Apache AGE shared library into the session
and sets C<search_path> to include C<ag_catalog>. Must be called before any
graph operations.

=cut

sub create_graph {
  my ($self, $name) = @_;
  $self->dbh->do('SELECT * FROM ag_catalog.create_graph(?)', undef, $name);
}

=method create_graph

  $storage->create_graph('social');

Creates a new Apache AGE graph with the given name.

=cut

sub drop_graph {
  my ($self, $name, $cascade) = @_;
  $self->dbh->do(
    'SELECT * FROM ag_catalog.drop_graph(?, ?)',
    undef, $name, $cascade ? 1 : 0,
  );
}

=method drop_graph

  $storage->drop_graph('social');
  $storage->drop_graph('social', 1);  # cascade

Drops the named graph. Pass a true second argument to cascade the drop to all
vertices and edges within the graph.

=cut

sub cypher {
  my ($self, $graph, $query, $columns, $params) = @_;

  my $col_spec = join ', ', map { "$_ agtype" } @$columns;

  my @bind = ($graph);
  my $sql;

  if ($params && %$params) {
    require JSON::MaybeXS;
    my $json = JSON::MaybeXS->new(utf8 => 1, canonical => 1)->encode($params);
    push @bind, $json;
    $sql = "SELECT * FROM cypher(?, \$\$\n$query\n\$\$, ?) AS ($col_spec)";
  }
  else {
    $sql = "SELECT * FROM cypher(?, \$\$\n$query\n\$\$) AS ($col_spec)";
  }

  return $self->dbh->selectall_arrayref($sql, { Slice => {} }, @bind);
}

=method cypher

  my $rows = $storage->cypher(
    'social',
    $$ MATCH (a:Person)-[:KNOWS]->(b:Person) RETURN a.name, b.name $$,
    [qw( person friend )],
  );

  # With Cypher parameters:
  my $rows = $storage->cypher(
    'social',
    $$ MATCH (n:Person {name: $name}) RETURN n $$,
    ['node'],
    { name => 'Alice' },
  );

Executes a Cypher query against the named graph. C<$columns> is an arrayref
of result column names; all are declared as C<agtype>. Returns an arrayref
of hashrefs with one key per column.

An optional C<$params> hashref is JSON-encoded and passed as AGE's third
argument to C<cypher()> for parameterized queries.

=seealso

=over 4

=item * L<DBIO::PostgreSQL::Age> - Schema component that activates this storage

=back

=cut

1;
