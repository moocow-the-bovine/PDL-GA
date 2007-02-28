#!/usr/bin/perl -wd

use lib qw(./blib/lib ./blib/arch);
use PDL;
use PDL::GA;
use PDL::Graphics::PGPLOT;
use Benchmark qw(timethese cmpthese);

BEGIN{
  $, = ' ';
  #dev('/XWINDOW');
}

##---------------------------------------------------------------------
## Weight selection
sub testweights1 {
  our $wmap = pdl([0,1,2,3]) if (!defined($wmap));
  our $nsel = 10 if (!defined($nsel));
  our $wsel    = random($nsel)*$wmap->flat->sumover;
  our $indices = zeroes(long,$nsel);
}

sub wsel {
  testweights1();
  our ($wmap,$wsel,$indices);
  weightselect($wmap, $wsel, $indices);
  #wsel_eval();
}

sub wsel_eval_basic {
  our ($wmap,$indices);
  our $wprob = flat($wmap / $wmap->flat->sumover);
  our $whist = hist($indices->flat, 0, $wmap->nelem, 1);
  our $whistp = $whist->convert(float) / $whist->sumover;
}
sub wsel_eval {
  wsel_eval_basic();
  print "diff = ", ($wprob-$whistp), "\n";
}
sub wsel_plot {
  wsel_eval_basic;
  our ($wmap,$indices);
  line($whistp,{COLOR=>'red'});
  hold();
  line($wprob,{COLOR=>'blue'});
  release();
}
sub wsel_plot_error {
  wsel_eval_basic;
  line($wprob,{COLOR=>'blue'});
  hold();
  line($whistp,{COLOR=>'red'});
  hold();
  line($wprob-$whistp+$wprob->minimum,{COLOR=>'black'});
  release();
}


sub rsel {
  testweights1();
  our ($wmap,$nsel);
  our $indices = roulette($wmap,n=>$nsel);
  #wsel_eval();
}


##---------------------------------------------------------------------
## repetition removal

sub test_make_unique {
  our $S = 3;
  our $M = 4;
  our $indices = pdl(long,[0,1,1]);
  our $try     = sequence(long,$M)+1;             ##-- increment-map
  #our $try     = sequence(long,$M)-1;             ##-- decrement-map
  #our $try     = sequence(long,$M)-2;             ##-- double-decrement-map
  #our $try     = zeroes(long,$M);                 ##-- constant-map: loop $M times & map second "1" to "0"
  #our $try     = sequence(long,$M);              ##-- identity-map: try & fail once, map second "1" to "1"
  #our $try     = zeroes(long,$M)->setvaltobad(0); ##-- bad values: map duplicates to 'BAD'
  our $uindices = ga_make_unique($indices,$try);
}
#test_make_unique();


##---------------------------------------------------------------------
## Selection, no repeats

sub wdata_nr {
  our $wmap    = sequence(double,100) if (!defined($wmap));
  our $cwmap   = $wmap->cumusumover;
  our $niter   = 10 if (!defined($niter)); ##-- outer: number of selection iterations
  our $nsel    = 10 if (!defined($nsel));  ##-- inner: number of selections per iteration
                                           ##   (*select_nr() methods don't within $nsel)
  our $wsel    = random($nsel,$niter) * $cwmap->at(-1);
  our $indices = zeroes(long,$nsel,$niter);
}
wdata_nr();

sub plot_cumuweightselect_nr {
  wdata_nr;
  $indices = cumuweightselect_nr($cwmap, $wsel);
  wsel_eval_basic;
  wsel_plot;
}


##---------------------------------------------------------------------
## Mutation

sub testpop1 {
  #our $ngenes = 3;
  #our $popsize = 2;
  ##--
  our $ngenes = 50;
  our $popsize = 100;

  our ($min,$max)   = (sequence(long,$ngenes)+1, (sequence(long,$ngenes)+1)*100);
  our ($minc,$maxc) = (pdl(long,1),pdl(long,100));
  #our $indiv = ($min+random($ngenes)*($max-$min))->convert(long);
  #our $indiv = mutate_range(zeroes(long,$ngenes),1.0,$min,$max);
  our $src = -sequence(long, $ngenes,$popsize)-1;
  our $pop = $src;
  our $rate = 0.5;
}

sub dims_match {
  my ($p,@dims) = @_;
  return 0 if ($p->ndims != @dims);
  foreach (0..$#dims) {
    return 0 if ($p->dim($_) != $dims[$_]);
  }
  return 1;
}
sub ensure_match {
  my ($src,$dst) = @_;
  if (!defined($dst)) {
    return $dst = pdl($src);
  } elsif (!dims_match($dst,$src->dims)) {
    $dst->resize($src->dims);
  }
  return $dst .= $src;
}


sub testmutate_range {
  our $pop1 = mutate_range($pop,   1.0, $min,$max);
  our $pop2 = mutate_range($pop1,$rate, $min,$max);
}
sub testmutate_range1 {
  our $pop1 = mutate_range1($pop,   1.0, $min,$max);
  our $pop2 = mutate_range1($pop1,$rate, $min,$max);
}


sub testmutate_add {
  our $pop1 = mutate_range   ($pop,  1.0, 0,10);
  our $pop2 = mutate_addrange($pop1, 0.5, 1,10);
}

sub testmutate_bool {
  our $pop1 = mutate_bool(zeroes(byte,$pop->dims), 0.5);
  our $pop2 = mutate_bool($pop1, 0.5);
}


sub testmutate_bits {
  our $pop1 = mutate_range(zeroes(byte,$pop->dims), 1.0, 0,255);
  our $pop2 = mutate_bits($pop1, 0.5);
}

##---------------------------------------------------------------------
## Crossover (low-level)

sub testpopx {
  our $ngenes = 3;
  our $popsize = 2;
  our $pop = 1+sequence(long,$ngenes,$popsize);
  $pop->slice(",(1)") *= -1;
  our ($p1,$p2) = ($pop->slice(",(0)"), $pop->slice(",(1)"));
}

sub cross1 {
  my ($p1,$p2) = @_;
  my $x        = 1+int(rand($p1->nelem)-1);
  my ($k1,$k2) = (pdl($p1),pdl($p2));
  $k1->slice("$x:-1")     .= $p2->slice("$x:-1");
  $k2->slice("$x:-1")     .= $p1->slice("$x:-1");
  return ($k1,$k2);
}

sub testx1 {
  our $mom = (1+sequence(3,4));
  our $dad = -(1+sequence(3,4));
  our $xpoints=sequence(4);
  our $kids1 = _xover1($mom,$dad,$xpoints);
  our $kids2 = _xover1($dad,$mom,$xpoints);
}

sub testx2 {
  our $mom = (1+sequence(3,4));
  our $dad = -(1+sequence(3,4));
  our $xstart = pdl([0,0,1,2]);
  our $xend   = pdl([1,2,1,3]);
  our $kids1  = _xover2($mom,$dad,$xstart,$xend);
  our $kids2  = _xover2($mom,$dad,$xstart,$xend);
}

##---------------------------------------------------------------------
## Generation

sub testga1 {
  our $ngenes = 50 if (!defined($ngenes));

  #our $popsize = 10 if (!defined($popsize));
  our $popsize = 100 if (!defined($popsize));

  our $mutateRate = 0.01 if (!defined($mutateRate));
  #our $mutateRate = 0.1 if (!defined($mutateRate));
  #our $mutateRate = 0.25 if (!defined($mutateRate));

  our $xoverRate  = 0.95 if (!defined($xoverRate));

  #our $pop = mutate_bool(zeroes(byte,$ngenes,$popsize), 0.5);
  #our $pop = xvals(byte,$ngenes,$popsize) < yvals(byte,$ngenes,$popsize);
  #our $pop = mutate_bool(zeroes(byte,$ngenes,$popsize), 0.25);
  our $pop = mutate_bool(zeroes(byte,$ngenes,$popsize), 0.1);
  #our $pop = zeroes(byte,$ngenes,$popsize);
  our $ga = {
	     pop=>$pop,
	     mutateRate=>$mutateRate,
	     xoverRate=>$xoverRate,
	     ##
	     fitnessSub=>sub {
	       return $_[0]{pop}->sumover;
	     },
	     mutateSub=>sub {
	       my $ga = shift;
	       mutate_bool($ga->{pop}->inplace, $ga->{mutateRate});
	     },
	     xoverSub=>sub {
	       my $ga = shift;
	       my ($moms,$dads) = selectps($ga->{parents}, $ga->{fitness});
	       return $ga->{pop} = xover2($moms, $dads, $ga->{xoverRate});
	     },
	     keepSub=>sub {
	       my $ga = shift;
	       $ga->{pop}->dice_axis(-1,0) .= $ga->{parents}->dice_axis(-1,$ga->{fitness}->maximum_ind);
	     },
	    };
}

sub testga2 {
  our $ngenes = 50 if (!defined($ngenes));
  our $popsize = 100 if (!defined($popsize));

  our $mutateRate = 0.01;
  #our $mutateRate = 0.1;
  #our $mutateRate = 0.25;

  our $xoverRate  = 0.95;

  our $pop = mutate_range(zeroes(byte,$ngenes,$popsize), 1.0, 0,$ngenes);
  our $ga = {
	     pop=>$pop,
	     mutateRate=>$mutateRate,
	     xoverRate=>$xoverRate,
	     ##
	     fitnessSub=>sub {
	       my $pop = $_[0]{pop};
	       return ((1+abs(sequence($ngenes)->slice(",*$popsize") - $pop))**-1)->sumover
	     },
	     mutateSub=>sub {
	       my $ga = shift;
	       mutate_range($ga->{pop}->inplace, $ga->{mutateRate}, 0,1);
	     },
	     xoverSub=>sub {
	       my $ga = shift;
	       my ($moms,$dads) = selectps($ga->{parents}, $ga->{fitness});
	       return $ga->{pop} = xover2($moms, $dads, $ga->{xoverRate});
	     },
	     keepSub=>sub {
	       my $ga = shift;
	       $ga->{pop}->dice_axis(-1,0) .= $ga->{parents}->dice_axis(-1,$ga->{fitness}->maximum_ind);
	     },
	    };
}


sub testga3 {
  our $ngenes = 5 if (!defined($ngenes));
  our $popsize = 10 if (!defined($popsize));

  #our $mutateRate = 0.01;
  #our $mutateRate = 0.1;
  our $mutateRate = 0.25;

  our $xoverRate  = 0.95;

  our $pop = mutate_range(zeroes(float,$ngenes,$popsize), 1.0, 0,1);
  our $ga = {
	     pop=>$pop,
	     mutateRate=>$mutateRate,
	     xoverRate=>$xoverRate,
	     ##
	     fitnessSub=>sub {
	       my $pop = $_[0]{pop};
	       return (1+abs($pop->sumover-1))**-1;
	     },
	     mutateSub=>sub {
	       my $ga = shift;
	       mutate_range($ga->{pop}->inplace, $ga->{mutateRate}, 0,1);
	     },
	     xoverSub=>sub {
	       my $ga = shift;
	       my ($moms,$dads) = selectps($ga->{parents}, $ga->{fitness});
	       return $ga->{pop} = xover2($moms, $dads, $ga->{xoverRate});
	     },
	     keepSub=>sub {
	       my $ga = shift;
	       $ga->{pop}->dice_axis(-1,0) .= $ga->{parents}->dice_axis(-1,$ga->{fitness}->maximum_ind);
	     },
	    };
}


sub selectps {
  my ($pop,$fitness) = @_;
  my $moms = $pop->dice_axis(-1,roulette($fitness, n=>$pop->dim(-1)));
  my $dads = $pop->dice_axis(-1,roulette($fitness, n=>$pop->dim(-1)));
  return ($moms,$dads);
}

sub generate {
  my $ga = shift;
  $ga = $main::ga if (!defined($ga));

  ##-- compuate & cache fitness
  $ga->{fitness} = $ga->{fitnessSub}->($ga);

  ##-- cache parent population
  $ga->{parents} = $ga->{pop};

  ##-- crossover (set/update $ga->{pop})
  $ga->{xoverSub}->($ga) if (defined($ga->{xoverSub}));

  ##-- mutation (set/update $ga->{pop})
  $ga->{mutateSub}->($ga) if (defined($ga->{mutateSub}));

  ##-- immortality ("golden cage") (set/update $ga->{pop})
  $ga->{keepSub}->($ga) if (defined($ga->{keepSub}));

  return $ga;
}

sub maxit1 {
  $maxfitness = shift;
  $maxfitness = 50 if (!defined($maxfitness));
  testga1 if (!defined($ga));
  for ($i=0; $i < 10000; $i++) {
    generate();
    last if ($ga->{fitness}->max >= $maxfitness);
  }
}

sub maxit2 {
  $maxgens = shift;
  $maxgens = 500 if (!defined($maxgens));
  testga2 if (!defined($ga));
  for ($i=0; $i < $maxgens; $i++) {
    generate();
  }
}


##---------------------------------------------------------------------
## DUMMY
##---------------------------------------------------------------------
foreach $i (0..3) {
  print "--dummy($i)--\n";
}
