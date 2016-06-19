package DemoHelper;
  use Moose;

  # We don't need this class. It was used for early benchmarking

  has 'id' => (is => 'rw', isa => 'Str');
  has 'bib' => (is => 'rw', isa => 'Str');
  has 'bbl' => (is => 'rw', isa => 'Str');
  has 'bbl_clean' => (is => 'rw', isa => 'Str');
  has 'old_html' => (is => 'rw', isa => 'Str'); 
  has 'new_html' => (is => 'rw', isa => 'Str'); 

  has 'gentime_old' => (is => 'rw', isa => 'Str'); 
  has 'gentime_new' => (is => 'rw', isa => 'Str'); 

  has 'html_contains_em' => (is => 'rw', isa => 'Str'); 
  has 'bbl_clean_contains_rubbish' => (is => 'rw', isa => 'Str'); 
  has 'warnings' => (is => 'rw', isa => 'Str');
  

no Moose;
__PACKAGE__->meta->make_immutable;

1;