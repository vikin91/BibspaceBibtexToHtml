
use strict;
use warnings;
use v5.10;
use Data::Dumper;
use Time::HiRes qw( time );

#http://cpansearch.perl.org/src/NODINE/Text-BibTeX-BibStyle-0.03/lib/Text/BibTeX/BibStyle.pm
use FindBin;
use lib $FindBin::Bin;
use BibSpaceBibtexToHtml;
use DemoHelper;

my $how_many = $ARGV[0] // 10;
my @demo_helpers = ();

use DBI;
my $dbh = DBI->connect("DBI:mysql:database=bibspace;host=localhost","bibspace_user", "passw00rd",{'RaiseError' => 1});
my $cmd = "mysql -u bibspace_user -ppassw00rd bibspace  < ../publiste/fixture/db.sql";
`$cmd`;

my $qry = "SELECT DISTINCT id, bib FROM Entry LIMIt 0,$how_many";
my $sth = $dbh->prepare( $qry );
$sth->execute();
while(my $row = $sth->fetchrow_hashref()) {

  my $z = DemoHelper->new();
  $z->{id} = "you don't need this";
  $z->{bib} = $row->{bib};
  push @demo_helpers, $z;
}



my @strange_bibzz;
{
  my $zs1 = DemoHelper->new();
  $zs1->{id} = "0";
  $zs1->{bib} = '@incollection{test-polish-and-german-language,
     author = {James Bond},
     booktitle = {\"{A}\"{a}nder {\em ung} \"{A} \"{U}\"{u}ber \"{O}\"{o}ven},
     editor = {Adam Z},
     note = { ZA\.{Z}\\\'{O}\\L{}\\\'{C} G\k{E}\\\'{S}L\k{A} JA\\\'{Z}\\\'{N} },
     pages = {1--5},
     publisher = {Exit},
     title = {{ Za\.{z}\\\'{o}\\l{}\\\'{c} g\k{e}\\\'{s}l\k{a} ja\\\'{z}\\\'{n} }},
     year = {2010},
   }';

   push @strange_bibzz, $zs1;
}
{
  my $zs1 = DemoHelper->new();
  $zs1->{id} = "0";
  $zs1->{bib} = '@article{happe2009a,
  abstract = {Performance prediction methods can help software architects to identify potential performance problems, such as bottlenecks, in their software systems during the design phase. In such early stages of the software life-cycle, only a little information is available about the system?s implementation and execution environment. However, these details are crucial for accurate performance predictions. Performance completions close the gap between available high-level models and required low-level details. Using model-driven technologies, transformations can include details of the implementation and execution environment into abstract performance models. However, existing approaches do not consider the relation of actual implementations and performance models used for prediction. Furthermore, they neglect the broad variety of possible implementations and middleware platforms, possible configurations, and possible usage scenarios. In this paper, we (i) establish a formal relation between generated performance models and generated code, (ii) introduce a design and application process for parametric performance completions, and (iii) develop a parametric performance completion for Message-oriented Middleware according to our method. Parametric performance completions are independent of a specific platform, reflect performance-relevant software configurations, and capture the influence of different usage scenarios. To evaluate the prediction accuracy of the completion for Message-oriented Middleware, we conducted a real-world case study with the SPECjms2007 Benchmark [http://www.spec.org/jms2007/]. The observed deviation of measurements and predictions was below 10% to 15%},
  author = {Jens Happe and Steffen Becker and Christoph Rathfelder and Holger Friedrich and Ralf H. Reussner},
  doi = {10.1016/j.peva.2009.07.006},
  journal = {Performance Evaluation (PE)},
  month = {August},
  number = {8},
  pages = {694--716},
  publisher = {Elsevier},
  title = {{P}arametric {P}erformance {C}ompletions for {M}odel-{D}riven {P}erformance {P}rediction},
  url = {http://dx.doi.org/10.1016/j.peva.2009.07.006},
  volume = {67},
  year = {2010},
}';

   push @strange_bibzz, $zs1;
}
{
  my $zs1 = DemoHelper->new();
  $zs1->{id} = "0";
  $zs1->{bib} = '@inproceedings{CaSpWa2016-ICPE-AutomatedParameterizationTutorial,
  author = {Giuliano Casale and Simon Spinner and Weikun Wang},
  title = {{Automated Parameterization of Performance Models from Measurements}},
  titleaddon = {{(Tutorial Paper)}},
  year = {2016},
  month = {March},
  day = {12},
  location = {Delft, the Netherlands},
  booktitle = {{Proceedings of the 7th ACM/SPEC International Conference on Performance Engineering (ICPE 2016)}},
  abstract = {Estimating parameters of performance models from empirical measurements is a critical task, which often has a major influence on the predictive accuracy of a model. This tutorial presents the problem of parameter estimation in queueing systems and queueing networks. The focus is on reliable estimation of the {\em arrival rates} of the requests and of the {\em service demands} they place at the servers. The tutorial covers common estimation techniques such as regression methods, maximum-likelihood estimation, and moment-matching, discussing their sensitivity with respect to data and model characteristics. The tutorial also demonstrates the automated estimation of model parameters using new open source tools.},
  pdf = {http://example.com////pa/publications/download/paper/924.pdf},
}';

   push @strange_bibzz, $zs1;
}

#uncomment to test strange bibz

if(@strange_bibzz and !@demo_helpers){
  @demo_helpers = @strange_bibzz;
}

my %hist;

foreach my $z (@demo_helpers){

  my $c = BibSpaceBibtexToHtml->new();
  my $bib = $z->{bib};
  my $code_new = "";

  

  my $ss = time();
  $code_new = $c->convert_to_html({method => 'new', bib => $bib, bst => './descartes2.bst'});  
  my $ee = time();
  $bib =~ m/@(.*)\{(.*),/;
  my $gues_key  = $2;
  

  $z->{bbl} = $c->{bbl};
  $z->{bbl_clean} = $c->{bbl_clean};
  $z->{warnings} = join(', ', @{ $c->{warnings_arr} } );
  
  $z->{new_html} = $code_new;
  $z->{html_contains_em} = $c->html_contains_em();
  $z->{bbl_clean_contains_rubbish} = $c->bbl_clean_contains_rubbish();

  my $ss_old = time();
  my $code_old = "";
  $code_old = $c->convert_to_html({method => 'old', bib => $bib, bst => './descartes2.bst'});
  my $ee_old = time();
  $z->{old_html} = $code_old;

  
  
  my $dur_new = $ee - $ss;
  my $dur_old = $ee_old - $ss_old;
  $hist{$gues_key} = $dur_new;

  $z->{gentime_old} = substr($dur_old, 0, 5);
  $z->{gentime_new} = substr($dur_new, 0, 5);

  printf("%.2f s/ %.2f s = (OLD/NEW) html generation BibTeX entry: $gues_key.\n", $dur_old, $dur_new);
}



# foreach my $bib_key (sort { $hist{$a} <=> $hist{$b} } keys %hist) {
#     printf "%-3s %s\n", $hist{$bib_key}, $bib_key;
# }




######## Generate a report

my $out_html = "<html><head>";
$out_html .= '<script src="http://code.jquery.com/jquery-latest.min.js" type="text/javascript"></script>';
$out_html .= '<script type="text/javascript">
         function showAbstract(divid) {
            $(\'div#\'+divid).toggle(); 
         };
  </script>';
$out_html .= '<style media="screen" type="text/css">';
$out_html .= '.em {background: #AAF;}';
$out_html .= '</style>';
$out_html .= "</head><body>\n";


$out_html .= "<hr/>\n";

my $num_with_em = 0;
my $num_with_rubbish = 0;
my $key_with_em = " <br/>\n ";
my $key_with_rubbish = " <br/>\n ";

foreach my $href (@demo_helpers){
  $out_html .= "<h3>Input bib</h3>\n";
  $out_html .= "<div class=\"INPUT_BIB\" style=\"width: 900px; background: #fff;\">\n\t";
  $out_html .= "<pre>".$href->{bib}."</pre>\n" if defined $href->{bib};
  $out_html .= "</div>\n";

  $out_html .= "<h3>Output HTML old method (using bibtex2html) - Generation time ".$href->{gentime_old}." s</h3>\n";
  $out_html .= "<div class=\"OLD\" style=\"width: 900px; background: #AAA;\">\n\t";
  $out_html .= $href->{old_html}."\n" if defined $href->{old_html};
  $out_html .= "</div>\n";
  my $color = '#AFA';
  my $bbl_color = '#FFF';

  $href->{bib} =~ m/@(.*)\{(.*),/;
  my $gues_key  = $2;
  

  if($href->{bbl_clean_contains_rubbish}){
    $bbl_color = '#F00';
    $num_with_rubbish = $num_with_rubbish +1;
    $key_with_rubbish .=  $gues_key." <br/>\n ";
  }
  if($href->{html_contains_em}){
    $color = '#FAA';
    $num_with_em = $num_with_em +1;
    $key_with_em .=  $gues_key." <br/>\n ";
  }

  $out_html .= "<h3>Output HTML new method (using BibSpaceBibtexToHtml) - Generation time ".$href->{gentime_new}." s</h3>\n";
  $out_html .= "<div class=\"NEW\" style=\"width: 900px; background: $color;\">\n\t";
  $out_html .= $href->{new_html}."\n" if defined $href->{new_html};
  $out_html .= "</div>\n";
  $out_html .= "<h3>Partial: dirty bbl</h3>\n";
  $out_html .= "<div class=\"BBL\" style=\"width: 900px; background: #EEE;\">\n\t";
  $out_html .= "<pre>".$href->{bbl}."</pre>\n" if defined $href->{bbl};
  $out_html .= "</div>\n";
  $out_html .= "<h3>Partial: clean bbl</h3>\n";
  $out_html .= "<div class=\"BBL_clean\" style=\"width: 900px; background: $bbl_color;\">\n\t";
  $out_html .= "<pre>".$href->{bbl_clean}."</pre>\n" if defined $href->{bbl_clean};
  $out_html .= "</div>\n";

  if(defined $href->{warnings} and $href->{warnings} ne ''){
    $out_html .= "<h3>Partial: warnings</h3>\n";
    $out_html .= "<div class=\"warnings\" style=\"width: 900px; background: yellow;\">\n\t";
    $out_html .= "<pre>".$href->{warnings}."</pre>\n" ;
    $out_html .= "</div>\n";  
  }

  $out_html .= "<hr/>\n";
}

$out_html .= "<h3>Checks:</h3>\n";
$out_html .= "<h4>If all below fields are 0 or empty then the 'test' is passed.</h4>\n";
$out_html .= "num_with_em: $num_with_em <br/>\n";
$out_html .= "key_with_em: $key_with_em <br/>\n";
$out_html .= "num_with_rubbish: $num_with_rubbish <br/>\n";
$out_html .= "key_with_rubbish: $key_with_rubbish <br/>\n";

$out_html .= "\n</body></html>";

open (my $MYFILE, q{>}, 'conversion_report.html');
print $MYFILE $out_html;
close ($MYFILE); 


 