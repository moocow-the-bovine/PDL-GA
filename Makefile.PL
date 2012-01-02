use PDL::Core::Dev;
use ExtUtils::MakeMaker;
PDL::Core::Dev->import();
require "pdlmaker.plm";

$package = ["GA.pd",GA,PDL::GA];
%hash = pdlmaker_init($package);

$hash{AUTHOR} = 'Bryan Jurish';
$hash{ABSTRACT} = 'Genetic algorithm utilities for PDL';
$hash{PREREQ_PM}{PDL} = '2.4.2'; ##-- ensure PDL-ability
push(@{$hash{LIBS}}, '-lm');
#$hash{INC} .= '';
$hash{DIR} = [];
#$hash{OBJECT} .= '';
$hash{VERSION_FROM} = 'GA.pd';
$hash{realclean}{FILES} .= '*~ *.tmp README.txt';

WriteMakefile(%hash);
