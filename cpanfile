requires 'perl', '5.020';

requires 'DBIO';
requires 'DBIO::PostgreSQL';
requires 'JSON::MaybeXS';

on test => sub {
  requires 'Test::More', '0.98';
};
