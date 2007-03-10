## Signature: (pop(G,P); min(G); max(G); [o]dst(G,P))
sub mutate_range_argh {
  my ($pop,$rate,$min,$max,$dst) = @_;
  if (!defined($dst)) {
    if ($src->is_inplace) {
      $dst = $src;
    } else {
      $dst = pdl($src);
    }
  }
  $dst = ensure_match($pop,$dst);
  my $mutate_i_nd = (PDL->random($dst->dims) < $rate)->whichND;
  my $mutate_min  = $min->index($mutate_i_nd->dice_axis(0)->flat);
  my $mutate_max  = $max->index($mutate_i_nd->dice_axis(0)->flat);
  my $mutate      = $dst->indexND($mutate_i_nd);
  $mutate        .= $mutate_min;
  $mutate        += (PDL->random($mutate->dims))*($mutate_max-$mutate_min);
  return $dst;
}


## Signature: (pop(G,P); rate(G); min(G); max(G); [o]dst(G,P))
sub mutate_range_1 {
  my ($src,$rate,$min,$max,$dst) = @_;
  $dst = pdl($src) if (!defined($dst));
  my $mutate_i_nd = (PDL->random($dst->dims) < $rate)->whichND;
  my $mutate_min  = $min->index($mutate_i_nd->dice_axis(0)->flat);
  my $mutate_max  = $max->index($mutate_i_nd->dice_axis(0)->flat);
  my $mutate      = $dst->indexND($mutate_i_nd);
  $mutate        .= $mutate_min;
  $mutate        += (PDL->random($mutate->dims))*($mutate_max-$mutate_min);
  return $dst;
}

## Signature: (pop(G,P); rate(); min(); max(); [o]dst(G,P))
sub mutate_range_c {
  my ($src,$rate,$minc,$maxc,$dst) = @_;
  $dst = pdl($src) if (!defined($dst));
  my $mutate_i = (PDL->random($dst->nelem) < $rate)->which;
  $dst->flat->index($mutate_i) .= $minc + (PDL->random($mutate_i->nelem))*($maxc-$minc);
  return $dst;
}

## Signature: (pop(G,P); rate(); [o]dst(G,P))
sub mutate_bool {
  my ($genes,$rate,$mutated) = @_;
  if ($genes->is_inplace) {
    $mutated = $genes;
  } elsif (!defined($mutated)) {
    $mutated = pdl($genes);
  } else {
    $mutated .= $genes;
  }
  my $mutate_i = (PDL->random($mutated->nelem) < $rate)->which;
  if (!$mutate_i->isempty) {
    $mutated->flat->index($mutate_i)->inplace->not();
  }
  return $mutated;
}

## Signature: (ints(); [o]bits(B))
sub tobits_1 {
  my ($ints,$bits) = @_;
  my $itype = $ints->type;
  my $nbits = 8*PDL::howbig($itype);
  $bits = zeroes($nbits,$ints->dims) if (!defined($bits));
  return
    $bits .= ($ints->flat->slice("*1,") & (pdl($itype,2)**sequence($nbits)))->reshape($nbits,$ints->dims);
}
