package BibSpaceBibtexToHtml;
  use Text::BibTeX;  
  use LocalBibStyle; #Text::BibTeX::BibStyle;
  use Data::Dumper;
  use v5.10;
  use utf8;
  use Cwd;
  use File::Slurp;
  use Moose;
  use Pod::LaTeX;



  has 'bst' => (is => 'rw', isa => 'Str');
  has 'bib' => (is => 'rw', isa => 'Str');
  has 'html' => (is => 'rw', isa => 'Str'); 
  has 'html_tuned' => (is => 'rw', isa => 'Str'); 
  #
  #
  has 'bbl' => (is => 'ro', isa => 'Str'); 
  has 'bbl_clean' => (is => 'ro', isa => 'Str'); 
  has 'bbl_arr' => (is => 'rw', isa=>'ArrayRef[Str]'); 
  has 'warnings_arr' => (is => 'rw', isa=>'ArrayRef[Str]'); 

####################################################################################
sub reset {
  my $self = shift;
  $self->{bst} = "";
  $self->{bib} = "";
  $self->{html} = "";
  $self->{html_tuned} = "";

  $self->{bbl} = "";
  $self->{bbl_clean} = "";
  $self->{bbl_arr} = undef;
  $self->{warnings_arr} = undef;
}
####################################################################################
sub set_bib {
  my $self = shift;
  my $bib = shift;
  $self->{bib} = $bib;
}
####################################################################################
sub html_contains_em {
  my $self = shift;
  my $result = 0;
  $result = 1 if $self->{html_tuned} =~ m!\em!;
  return $result;
}
####################################################################################
sub bbl_clean_contains_rubbish {
  my $self = shift;
  my $result = 0;
  $result = 1 if $self->{bbl_clean} =~ m!bibitem!;
  $result = 1 if $self->{bbl_clean} =~ m!{!;
  $result = 1 if $self->{bbl_clean} =~ m!}!;
  $result = 1 if $self->{bbl_clean} =~ m!\\!;
  return $result;
}

####################################################################################
sub set_bst {
  my $self = shift;
  my $bst_path = shift;
  if(-e $bst_path){
    $self->{bst} = $bst_path;  
  }
  else{
    warn "Bst file does not exist! File: $bst_path";
  }
}
####################################################################################
sub convert_to_html {
  my $self = shift;
  my $opts_ref = shift;
  my %opts = %{$opts_ref};

  $self->reset();

  if($opts{'bib'}){
     $self->{bib} = $opts{'bib'};
  }
  if($opts{'bst'}){
     $self->{bst} = $opts{'bst'};
  }

  if($self->{bib} eq ''){
    warn "Cannot convert. BibTeX code not set!";
    return "ERROR: BIB";
  }
  if(!-e $self->{bst}){
    warn "Cannot convert. Bst file does not exist! File: $self->{bst}";
    return "ERROR: BST";
  }

  my $entry = new Text::BibTeX::Entry();
  $entry->parse_s($self->{bib});
  return "ERROR: BIBTEX PARSE" unless $entry->parse_ok;

  my $bibtex_key = $entry->key;


  if($opts{'method'} eq 'old'){
    my $tuned_html = $self->_convert_to_html_old_method();
    $self->{html_tuned} = $tuned_html;
  }
  else{
    my $tuned_html = $self->_convert_to_html_new_method();
    $self->{html_tuned} = $tuned_html;
  }

  return $self->{html_tuned};
}


####################################################################################
####################################################################################
####################################################################################
sub _convert_to_html_new_method {
  my $self = shift;
  my $bib = shift // $self->{bib};

  $self->{bib} = $bib;

  # stateless call
  my ($bbl_dirty, $dirty_bbl_array_ref, $warnings_arr_ref) = _convert_bib_to_bbl($bib, cwd.'/descartes2.bst');

  $self->{bbl} = $bbl_dirty;
  $self->{bbl_arr} = $dirty_bbl_array_ref;
  $self->{warnings_arr} = $warnings_arr_ref;


  # stateless call 
  my $clean_bbl = _clean_bbl($dirty_bbl_array_ref);
  $self->{bbl_clean} = $clean_bbl;


  my $html_code = _add_html_links($clean_bbl, $bib);
  $self->{html} = $html_code;
  

  my $tuned_html_code = "";
  # $tuned_html_code .= '<div class="bibtex_entry">'."\n";  
  $tuned_html_code .= $html_code;
  # $tuned_html_code .= "\n".'</div>';
  $self->{html_tuned} = $tuned_html_code;
  return $tuned_html_code;
}
####################################################################################
sub _convert_bib_to_bbl {
  my ($input_bib, $bst_file_path) = @_;


  my $bibstyle = LocalBibStyle->new(); #Text::BibTeX::BibStyle->new();
  $bibstyle->read_bibstyle($bst_file_path);

  my $bbl = $bibstyle->execute([], $input_bib);
  my $out = $bibstyle->get_output(); 
  my @a = $bibstyle->{output};

  my $warnings_arr_ref = $bibstyle->{warnings};

  #my @b = shift @a;
  #say Dumper \@b;
  my $bbl_dirty = join '', @{$bibstyle->{output}};
  my $dirty_bbl_array_ref = \@{$bibstyle->{output}};

  return ($bbl_dirty, $dirty_bbl_array_ref, $warnings_arr_ref);
}
####################################################################################
sub _clean_bbl {
  my ($bbl_arr_ref) = @_;

  my @arr = @{$bbl_arr_ref};
  my @useful_lines;

  foreach my $f (@arr){
    chomp $f;
    
    if($f =~ m/^\\begin/ or $f =~ m/^\\end/){
      # say "BB".$f;
    }
    elsif($f =~ m/\\bibitem/){
      # say "II".$f;
      push @useful_lines, $f;
    }
    elsif($f =~ m/^\s*$/){  # line containing only whitespaces
      ;
    }
    else{
      push @useful_lines, $f;
    }
  }

  my $useful_str = join '', @useful_lines;
  my $s = $useful_str;


  # say "\nXXXX1\n".$s."\nXXXX\n";

  $s =~ s/\\newblock/\n\\newblock/g; # every newblock = newline in bbl (but not in html!)
  $s =~ s/\\bibitem\{([^\}]*)\}/\\bibitem\{$1\}\n/; # new line after the bibtex key

  my ($bibtex_key, $rest) = $s =~ m/\\bibitem\{([^\}.]*)\}(.*)/; # match until the first closing bracket
  # extract the bibtex key and the rest - just in case you need it 

  $s =~ s/\\bibitem\{([^\}]*)\}\n?//; #remove first line with bibitem
  $s =~ s/\\newblock\s+//g; # remove newblocks


  # nested parenthesis cannot be handled with regexp :(
  # I use this because it counts brackets!
  # string_replace_with_counting($s, $opening, $closing, $avoid_l, $avoid_r, $opening_replace, $closing_replace)
  $s = string_replace_with_counting($s, '{\\em', '}', '{', '}', '<span class="em">', '</span>');
  
  # if there are more (what is very rare), just ignore
  $s = string_replace_with_counting($s, '{\\em', '}', '{', '}', '', '');
  # find all that is between {}, count all pairs of {} replace the outermost with nothing
  # does {zzz {aaa} ggg} => zzz {aaa} ggg

  $s = string_replace_with_counting($s, '\\url{', '}', '{', '}', '<span class="url">', '</span>');



  
  # and here are the custom replacement functions in case something goes wrong...
  $s = str_replace_german_letters($s);
  $s = str_replace_polish_letters($s);
  $s = str_replace_other_lanugages_letters($s);

  $s = str_replace_handle_tilde($s);

  my $new_s = "";
  $new_s = string_replace_with_counting($s, '{', '}', '{', '}', '', '');
  while($new_s ne $s){
    $s = $new_s;
    $new_s = string_replace_with_counting($s, '{', '}', '{', '}', '', '');
  }

  $s = str_replace_as_pod_latex($s);  # this should catch everything but it doesn't

  $s =~ s!\\%!&#37;!g; # replace % escape
  $s =~ s!\\&!&#38;!g; # replace & escape

  return $s;
}



####################################################################################
sub _add_html_links {
  my ($bbl_clean, $bib) = @_;
  
  my $s = $bbl_clean;

  my $entry = new Text::BibTeX::Entry();
  $entry->parse_s($bib);
  return -1 unless $entry->parse_ok;

  my $bibtex_key = $entry->key;

  $s .= "\n";

  my @code = ();

  if($entry->exists('pdf')){
    push @code, build_link('pdf', $entry->get('pdf'));
  }
  if($entry->exists('slides')){
    push @code, build_link('slides', $entry->get('slides'));
  }
  if($entry->exists('doi')){
    push @code, build_link('DOI', "http://dx.doi.org/".$entry->get('doi'));
  }
  if($entry->exists('url')){
    push @code, build_link('http', $entry->get('url'));
  }

  my $abstract_preview_a;
  my $abstract_preview_div;
  if($entry->exists('abstract')){
    my $content = $entry->get('abstract');
    $abstract_preview_a = '<a class="abstract-preview-a" onclick="showAbstract(\'abstract-of-'.$bibtex_key.'\')">Abstract</a>';
    $abstract_preview_div = '<div id="abstract-of-'.$bibtex_key.'" class="inline-bib" style="display:none;"><blockquote>'.$content.'</blockquote></div>';
    
  }


  
  my $bib_preview_a = '<a class="bib-preview-a" onclick="showAbstract(\'bib-of-'.$bibtex_key.'\')">bib</a>';
  my $bib_preview_div = '<div id="bib-of-'.$bibtex_key.'" class="inline-bib" style="display:none;"><pre>'.$bib.'</pre></div>';

  $s .= "[&nbsp;".$bib_preview_a;
  $s .= "&nbsp;|&nbsp;".$abstract_preview_a."\n" if defined $abstract_preview_a;
    
  while(my $e = shift @code){
    $s .= "&nbsp;|&nbsp;".$e."\n";
  }
  $s .= "&nbsp;]";

  $s =~ s/\|\&nbsp\;\]/\]/g;
  
  $s .= "\n".$bib_preview_div;
  $s .= "\n".$abstract_preview_div if defined $abstract_preview_div;


  $s;
}
####################################################################################
sub build_link {
  my $name = shift;
  my $value = shift;

  return "<a href=\"$value\" target=\"_blank\">$name</a>";

}





####### CORE
####################################################################################
sub str_replace_as_pod_latex {
my $s = shift;


  my %h = %Pod::LaTeX::HTML_Escapes;

  while(my($html, $tex) = each %h){
    next if $tex =~ m/^\$/;
    next if $html eq 'verbar'; # because it changes every letter to letter with vertialbar

    next if $tex eq '<';  # we want our html to stay
    next if $tex eq '>';  # we want our html to stay
    next if $tex eq '"';  # we want our html to stay
    next if $tex eq '\''; # we want our html to stay

    # escaping the stuff 
    $tex =~ s!\{!\\\{!g;
    $tex =~ s!\}!\\\}!g;
    $tex =~ s!\\!\\\\!g;


    $s =~ s![{}]!!g; # you need to remove this before decoding...

    # say "tex $tex -> $html" if $html =~ /ouml/;
    # say "BEFORE $s" if $html =~ /ouml/;
    $s =~ s!$tex!&$html;!g;
    # say "AFTER $s" if $html =~ /ouml/;

  } 


  $s;
}
####################################################################################
sub str_replace_handle_tilde {
  my $s = shift;
  $s =~ s!~!&nbsp;!g;

  $s;
}
####################################################################################
sub str_replace_polish_letters {
  my $s = shift;


  $s =~ s!\\k\{A\}!&#260;!g;
  $s =~ s!\\k\{a\}!&#261;!g;
  $s =~ s!\\k\{E\}!&#280;!g;
  $s =~ s!\\k\{e\}!&#281;!g;

  $s =~ s!\\L\{\}!&#321;!g;
  $s =~ s!\\l\{\}!&#322;!g;

  $s =~ s!\{\\L\}!&#321;!g; # people may have imagination
  $s =~ s!\{\\l\}!&#322;!g;

  $s =~ s!\\\.\{Z\}!&#379;!g;
  $s =~ s!\\\.\{z\}!&#380;!g;

  $s =~ s!\{\\\.Z\}!&#379;!g; #imagination again
  $s =~ s!\{\\\.z\}!&#380;!g;
# 
  # $s = decode('latex', $s); # does not work :(

  # http://www.utf8-chartable.de/unicode-utf8-table.pl

  $s = delatexify($s, '\'', 'Z', '&#377;');
  $s = delatexify($s, '\'', 'z', '&#378;');
  $s = delatexify($s, '\'', 'S', '&#346;');
  $s = delatexify($s, '\'', 's', '&#347;');
  $s = delatexify($s, '\'', 'C', '&#262;');
  $s = delatexify($s, '\'', 'c', '&#263;');
  $s = delatexify($s, '\'', 'N', '&#323;');
  $s = delatexify($s, '\'', 'n', '&#324;');
  $s = delatexify($s, '\'', 'O', '&#211;');
  $s = delatexify($s, '\'', 'o', '&#243;');

  $s;
}
####################################################################################
sub str_replace_german_letters {
  my $s = shift;

  # say "before replace: $s";

  $s =~ s!\\ss\{\}!&#223;!g;
  $s =~ s!\\ss!&#223;!g;


  $s = delatexify($s, '"', 'A', '&#196;');
  $s = delatexify($s, '"', 'a', '&#228;');
  $s = delatexify($s, '"', 'O', '&#214;');
  $s = delatexify($s, '"', 'o', '&#246;');
  $s = delatexify($s, '"', 'U', '&#220;');
  $s = delatexify($s, '"', 'u', '&#252;');

  $s;
}
####################################################################################
sub str_replace_other_lanugages_letters {
  my $s = shift;
  
  $s = delatexify($s, '\'', 'E', '&#201;');  # E with accent line pointing to the right
  $s = delatexify($s, '\'', 'e', '&#233;');

  $s = delatexify($s, '\'', 'A', '&#193;');
  $s = delatexify($s, '\'', 'a', '&#225;');

  $s = delatexify($s, '\'', 'I', '&#205;');
  $s = delatexify($s, '\'', 'i', '&#237;');
  

  $s = delatexify($s, '"', 'E', '&#203;');  # E with two dots (FR)
  $s = delatexify($s, '"', 'e', '&#235;');

  $s = delatexify($s, 'c', 'C', '&#268;');  # C with hacek (CZ)
  $s = delatexify($s, 'c', 'c', '&#269;');

  $s = delatexify($s, 'c', 'S', '&#352;');  # S with hacek (CZ)
  $s = delatexify($s, 'c', 's', '&#353;');

  $s;
}
####################################################################################
sub delatexify {
  my ($s, $accent, $src, $dest) = @_;

  $s =~ s!\\$accent\{$src\}!$dest!g;
  $s =~ s!\{\\$accent$src\}!$dest!g;
  $s =~ s!\\\{$accent$src\}!$dest!g;
  $s =~ s!\{$accent$src\}!$dest!g;
  $s =~ s!\\$accent$src!$dest!g;

  $s;
}
####################################################################################
sub string_replace_with_counting {
  my ($s, $opening, $closing, $avoid_l, $avoid_r, $opening_replace, $closing_replace) = @_;
  
  my $opening_len = length $opening;
  my $closing_len = length $closing;

  # $s = 'some szit {\em ddd c {{ ss} ssdfes {ddd} }dssddsw }ee';

  # say "======== string_replace_with_counting opening $opening closing $closing  ========";

  my $index_opening = -1;
  my $found_em = 0;
  my $index_closing = -1;

  my @str_arr = split //, $s;
  my $max = scalar @str_arr;

  my $l_brackets=0;
  my $r_brackets=0;

  for (my $i=0 ; $i < $max and $index_closing==-1 ; $i=$i+1) {  # we break when we find the first match
    my $c = $str_arr[$i];

    # say "$i - $c - L $l_brackets R $r_brackets == $found_em" if $opening eq '{';

    if($found_em==1){

      if($c eq $avoid_l){
        $l_brackets = $l_brackets + 1;
      }
      if($c eq $avoid_r){
        if($l_brackets==$r_brackets){
          $index_closing = $i;
        }
        if($l_brackets > 0){
          $r_brackets = $r_brackets + 1;
        }
      }
    }
    # if($c eq '{' and 
    #    $i+34 < $max and 
    #    $str_arr[$i+1] eq '\\' and 
    #    $str_arr[$i+2] eq 'e' and
    #    $str_arr[$i+3] eq 'm')
    if($found_em == 0 and substr($s, $i, $opening_len) eq $opening)
    {
      $index_opening = $i;
      $found_em = 1;
    }
  }
  # say "index_opening: $index_opening";
  # say "index_closing: $index_closing";

  if($found_em == 1){
    unless(
            ($index_opening == -1 and $index_closing == -1) or # both -1 are ok = no {\em ..}
            (  
              $index_opening > 0 and 
              $index_closing > 0 and    
              $index_closing > $index_opening
            )
          )
    {
      my $warn = "Indices are messed! No change made to string: ".substr($s, 0, 30)." ...\n";
      $warn .= "index_opening $index_opening index_closing $index_closing ".$index_opening*$index_closing."\n";

      warn $warn;

    }
    else{
      substr($s, $index_closing, $closing_len, $closing_replace); # first closing beacuse it changes the index!!!
      substr($s, $index_opening, $opening_len, $opening_replace);  

      # say "CHANGING OK:  $s";

    }
  }
  else{
    # say "EM not found in  ".substr($s, 0, 30)." ...\n";
  }

  # say "======== string_replace_with_counting END ========";
  return $s;
}

























####################################################################################
####################################################################################
####################################################################################
sub _convert_to_html_old_method {
  my $self = shift;

  if(!defined $self->{bib} or $self->{bib} eq ''){
    warn "Bib is empty!";
    return "";  
  }
  if(!defined $self->{bst} or $self->{bst} eq '' or !-e $self->{bst}){
    warn "Bst file not found or missing";
    return "";  
  }

  my $devnull = File::Spec->devnull();
  my $tmpdir = File::Spec->tmpdir();

  open (my $MYFILE, q{>}, 'input.bib');
  print $MYFILE $self->{bib};
  close ($MYFILE); 

  my $bibtex2html_command = "bibtex2html -s ".$self->{bst} ." -nf slides slides -d -r --revkeys -no-keywords -no-header -nokeys --nodoc -no-footer -o out.xxx input.bib";
  my $syscommand = "TMPDIR=. ".$bibtex2html_command.' &> '.$devnull;
  `$syscommand`;
  $self->{html} = read_file('out.xxx.html');

  $self->{html_tuned} = tune_html_old($self->{html}, $self->{bib}, "key");

  return $self->{html_tuned};
}
####################################################################################
sub tune_html_old{
  my $html = shift;
  my $bib = shift;
  my $key = shift // 'key';
  
  my $htmlbib = $bib;
  my $s = $html;

  $s =~ s/out_bib.html#(.*)/\/publications\/get\/bibtex\/$1/g;

  # FROM .pdf">.pdf</a>&nbsp;]
  # TO   .pdf" target="blank">.pdf</a>&nbsp;]
  # $s =~ s/.pdf">/.pdf" target="blank">/g;


  $s =~ s/>.pdf<\/a>/ target="blank">.pdf<\/a>/g;
  $s =~ s/>slides<\/a>/ target="blank">slides<\/a>/g;
  $s =~ s/>http<\/a>/ target="blank">http<\/a>/g;
  $s =~ s/>.http<\/a>/ target="blank">http<\/a>/g;
  $s =~ s/>DOI<\/a>/ target="blank">DOI<\/a>/g;

  $s =~ s/<a (.*)>bib<\/a>/BIB_LINK_ID/g;


  # # replace &lt; and &gt; b< '<' and '>' in Samuel's files.
  # sed 's_\&lt;_<_g' $FILE > $TMP && mv -f $TMP $FILE
  # sed 's_\&gt;_>_g' $FILE > $TMP && mv -f $TMP $FILE
  $s =~ s/\&lt;/</g;
  $s =~ s/\&gt;/>/g;


  # ### insert JavaScript hrefs to show/hide abstracts on click ###
  # #replaces every newline command with <NeueZeile> to insert the Abstract link in the next step properly 
  # perl -p -i -e "s/\n/<NeueZeile>/g" $FILE
  $s =~ s/\n/<NeueZeile>/g;

  # #inserts the link to javascript
  # sed 's_\&nbsp;\]<NeueZeile><blockquote><font size=\"-1\">_\&nbsp;\|\&nbsp;<a href=\"javascript:showAbstract(this);\" onclick=\"showAbstract(this)\">Abstract</a><noscript> (JavaScript required!)</noscript>\&nbsp;\]<div style=\"display:none;\"><blockquote id=\"abstractBQ\">_g' $FILE > $TMP && mv -f $TMP $FILE
  # sed 's_</font></blockquote><NeueZeile><p>_</blockquote></div>_g' $FILE > $TMP && mv -f $TMP $FILE
  # $s =~ s/\&nbsp;\]<NeueZeile><blockquote><font size=\"-1\">/\&nbsp;\|\&nbsp;<a href=\"javascript:showAbstract(this);\" onclick=\"showAbstract(this)\">Abstract<\/a><noscript> (JavaScript required!)<\/noscript>\&nbsp;\]<div style=\"display:none;\"><blockquote id=\"abstractBQ\">/g;


  #$s =~ s/\&nbsp;\]<NeueZeile><blockquote><font size=\"-1\">/\&nbsp;\|\&nbsp;<a class="abstract-a" onclick=\"showAbstract(\'$key\')\">Abstract<\/a>\&nbsp; \]<div id=\"$key\" style=\"display:none;\"><blockquote id=\"abstractBQ\">/g;
  $s =~ s/\&nbsp;\]<NeueZeile><blockquote><font size=\"-1\">/\&nbsp;\|\&nbsp;<a class="abstract-a" onclick=\"showAbstract(\'$key\')\">Abstract<\/a>\&nbsp; \] <div id=\"$key\" style=\"display:none;\"><blockquote class=\"abstractBQ\">/g;
  $s =~ s/<\/font><\/blockquote><NeueZeile><p>/<\/blockquote><\/div>/g;

  #inserting bib DIV marker
  $s =~ s/\&nbsp;\]/\&nbsp; \]/g;
  $s =~ s/\&nbsp; \]/\&nbsp; \] BIB_DIV_ID/g;

  $key =~ s/\./_/g;   

  # handling BIB_DIV_ID marker
  $s =~ s/BIB_DIV_ID/<div id="bib-of-$key" class="inline-bib" style=\"display:none;\"><pre>$htmlbib<\/pre><\/div>/g;
  # handling BIB_LINK_ID marker
  $s =~ s/BIB_LINK_ID/<a class="abstract-a" onclick=\"showAbstract(\'bib-of-$key\')\">bib<\/a>/g;

  # #undo the <NeueZeile> insertions
  # perl -p -i -e "s/<NeueZeile>/\n/g" $FILE
  $s =~ s/<NeueZeile>/\n/g;

  $s =~ s/(\s)\s+/$1/g;  # !!! TEST

  $s =~ s/<p>//g;
  $s =~ s/<\/p>//g;

  $s =~ s/<a name="(.*)"><\/a>//g;
  # $s =~ s/<a name=/<a id=/g;

  $s =~ s/\&amp /\&amp; /g;

  
  return $s;
}
####################################################################################
1;