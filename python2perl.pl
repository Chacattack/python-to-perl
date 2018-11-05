#!/usr/bin/perl
# Starting point for COMP2041/9041 assignment 
# http://www.cse.unsw.edu.au/~cs2041/assignments/python2perl
# written by andrewt@cse.unsw.edu.au September 2014
# edited by David Chacon

%keywords = ();
$indentLevel = 0;
$flag = 0;


while ($line = <>){
   push (@allLines, $line);
}

foreach $line (@allLines) {
   $flag = 0;
   whatToDo($line);
}

while ($indentLevel > 0){
   $indentLevel -= 3;
   indent($indentLevel);
   print "\}\n";
}
print "\n";

sub whatToDo {
   if ($flag == 0){
      backIndent($line);
      $flag = 1;
   }
   my $line = shift;
   $line =~ s/^\s*//;
   
   if ($line =~ /^#!\/usr\/bin\/python/){
         # translate #! line
         print "#!/usr/bin/perl -w\n";
	} elsif ($line =~ /^\s*#/ || $line =~ /^\s*$/) {	
		# Blank & comment lines can be passed unchanged
		print $line;
   } elsif ($line =~ /sys.stdin$/){
      print "\<STDIN\>";
   
	} elsif ($line =~ /^\s*print\s*"(.*)"\s*$/) {
	
		# Python's print print a new-line character by default
		# so we need to add it explicitly to the Perl print 
      #statement
		indent($indentLevel);
		print "print \"$1\\n\";\n";
   
   } elsif ($line =~ /\s*print\s*[0-9]+([\*\+\-\/][0-9]+)$/) {
      indent($indentLevel);
      @answer = split('=', $line)
      print "print $answer[1]"
   } elsif ($line =~ /\s*print\s*$/) {
      #deals with single print statement with no arguments
      indent($indentLevel);
      print "print \"\\n\";\n";
      
   } elsif ($line =~ /print.*%.*/) {
      #deals with printing with string formatting
      indent($indentLevel);
      @parts = split('% ', $line);
      @statement = split(' ', $parts[0]);
      @statement = @statement[1..$#statement];
      foreach $word (@statement){
         $word =~ s/\"//g;
      }
      print "printf \(\"@statement\\n\"";
      @arguments = split(' ', $parts[1]);
      foreach $arg (@arguments){
         print ", \$$arg";
      }
      print "\);\n";
      
   } elsif ($line =~ /^\s*[A-Za-z]+[0-9]* = (-)?[0-9]+\s*(\*\*\s*[0-9]+\s*)*\s*$/){
      #this will check if the line is using exponential
      @answer = split(' ', $line);
      $variableName = $answer[0];
      @answer = @answer[2..$#answer];
      $keywords{$variableName} = @answer;
      indent($indentLevel);
      print "\$$variableName = @answer;\n";
   
   } elsif ($line =~ /^\s*[A-Za-z]+[0-9]* = [0-9]+\s*([\+\-\/\*%]\s*[0-9]+\s*)*\s*$/){
      #this will check if the line is an assigning a value line of numeric value only
      chomp($line);
      @answer = split(' ', $line);
      $variableName = $answer[0];
      @answer = @answer[2..$#answer];
      $keywords{$variableName} = @answer;
      indent($indentLevel);
      print "\$$variableName = @answer;\n";
   
   } elsif ($line =~ /len\(.*\)/){
      #changes length function for perl use
      chomp($line);
      @statement = split(' ', $line);
      $variable = $statement[2];
      $variable =~ s/len\(//;
      $variable =~ s/\).*//;
      $firstWord = $statement[0];
      @statement = @statement[3..$#statement];
      indent($indentLevel);
      if ($variable =~ /\".*\"/){
         print "\$$firstWord = length\($variable\)";
      } else {
         print "\$$firstWord = scalar\(\@$variable\)";
      }
      foreach $e (@statement){
         if ($e =~ /int\(/){
            if ($e =~ /sys.stdin.readline\(\)/){
            $e =~ s/sys\.stdin\.readline\(\)/\<STDIN\>/;
            } 
            print "$e";
         } elsif ($e eq "and"){
            print "$e";
         } elsif ($e eq "or"){
            print "$e";
         } elsif ($e =~ /not/){
            print "$e";
         } elsif ($e =~ /^[A-Za-z]+[0-9]*/){
            print "\$$e";
         } else {
            print "$e";
         }
      }
      print ";\n";
   
   } elsif ($line =~ /.* = \[(.*)\]/){
      #translates python arrays to perl arrays
      chomp($line);
      @statement = split(' ', $line);
      @arguments = split ('\[', $line);
      $arguments[1] =~ s/\].*//;
      indent($indentLevel);
      if ($arguments[1] =~ /^\s*$/){
         print "\@$statement[0] = \"\";\n";
      } else {
         print "\@$statement[0] = \[$arguments[1]\];\n";
      }     
      
   } elsif ($line =~ /.*\.append\(/){
      #changes list operator append
      chomp($line);
      @statement = split('\.', $line);
      $variable = $statement[1];
      $variable =~ s/append\(//;
      $variable =~ s/\).*//;
      indent($indentLevel);
      print "chomp \$$variable;\n";
      indent($indentLevel);
      print "push \(\@$statement[0], \$$variable\);\n";
      
   } elsif ($line =~ /.*\.pop\(/){
      #changes list operator pop
      chomp($line);
      @statement = split('\.', $line);
      $variable = $statement[1];
      $variable =~ s/pop\(//;
      $variable =~ s/\).*//;
      indent($indentLevel);
      if ($variable eq ""){
         print "pop \(\@$statement[0]\);\n"; 
      } elsif ($variable =~ /[0-9]+/){
         print "pop \(\@$statement[0], $variable\);\n"; 
      } else {
         print "pop \(\@$statement[0], \$$variable\);\n"; 
      }
      
   } elsif ($line =~ /sort\(/){
      #deals with sorting lists/arrays
      chomp($line);
      @statement = split ('\(', $line);
      $statement[1] =~ s/\)//;
      $statement[1] =~ s/\s//;
      print "sort\(\@$statement[1]\);\n";
   
   } elsif ($line =~ /^\s*[A-Za-z]+[0-9]* = [A-Za-z]+[0-9]*\s*([\+\-\/\*%]\s*[A-Za-z]+[0-9]*\s*)*\s*/){
      #this will check if the line is assigning values of variables
      dealWithStatements($line);
      print ";\n";
   
   } elsif ($line =~ /^\s*print\s*([A-Za-z]+(,\s)?)+/){
      #this will deal with printing multiple variables on the one line
      printWithVariables($line);
      if ($line =~ /^\s*print\s*([A-Za-z]+(,\s)?)+$/){
         print "\\n\";\n";
      } else {
         print ",\"\\n\";\n";
      }
      
   } elsif ($line =~ /^\s*if/){
      chomp $line;
      ifStatement($line);
      print "\) \{\n";
      $line =~ s/\s//g;
      $line = chop $line;
      
      #used for single line expressions
      if ($line ne ":"){
         foreach $statement (@statements){
            whatToDo($statement);
         }      
         $indentLevel -= 3;
         indent($indentLevel);
         print "\}\n";
      }   
   
   } elsif ($line =~ /^\s*while/){
      chomp $line;
      whileExpression($line);
      print "\) \{\n";
      $line =~ s/\s//g;
      $line = chop $line;
      
      #used for single line expressions
      if ($line ne ":"){
         foreach $statement (@statements){
            whatToDo($statement);
         } 
         $indentLevel -= 3;
         indent($indentLevel);
         print "\}\n";
      }      
      
   } elsif ($line =~ /continue/){
      indent($indentLevel);
      print "continue;\n";
      
   } elsif ($line =~ /break/){
      indent($indentLevel);
      print "break;\n";
      
   } elsif ($line =~ /for.*range/){
      #deals with for x in range
      @expression = split(' ', $line);
      $variableName = $expression[1];
      indent($indentLevel);
      print "foreach \$$variableName \(";
      $indentLevel += 3;
      $line =~ s/.*\(//;
      $line =~ s/\).*//;
      @numbers = split (',', $line);
      $i = 0;
      foreach $number (@numbers){
         chomp $number;
         $number =~ s/^\s*//;
         if ($number =~ /[A-Za-z]/){
            $number = "\$$number";
         }
         if ($i == 1){
            $number = "$number - 1";
         }
         
         print "$number";
         
         if ($i == 0){
            print "..";
         }
         $i += 1;
      }
      print "\) \{\n";
      
   } elsif ($line =~ /for.*in/){
      #deals with for x in something
      @statement = split(' ', $line);
      $indentLevel += 3;
      $statement[3] =~ s/://;
      $statement[3] =~ s/\s//g;
      print "foreach \$$statement[1] \(";
      whatToDo($statement[3]);
      print "\) \{\n";
   
   } elsif ($line =~ /sys.stdout.write/){
      #deals with sys.stdout.write things
      chomp $line;
      $line =~ s/sys\.stdout\.write/print/;
      $line =~ s/^\s*//;
      $line =~ s/\s*$//;
      indent($indentLevel);
      #print "$indentLevel\n";
      print "$line;\n";
      
   } elsif ($line =~ /else/){
      indent($indentLevel);
      print "else \{\n";
      $indentLevel += 3;
   
   } elsif ($line =~ /sys.stdin.readlines\(\)/){
      #deals with sys.stdin.readlines()
      chomp($line);
      @statement = split(' ', $line);
      $statement[0] =~ s/^\s*//;
      if ($statement[0] eq "sys.stdin.readlines\(\)"){
         print "\<STDIN\>";
      } else {
         indent($indentLevel);
         print "\@$statement[0] = \<STDIN\>;\n";
      }
      
   } else {
		# Lines we can't translate are turned into comments
		print "#$line\n";
	}
}	

sub dealWithStatements {
   #works with statements passed in and appropriatly displays/formats it
   my $line = shift;
   my @answer = split(' ', $line);
   my $variableName = $answer[0];
   @answer = @answer[2..$#answer];
   $keywords{$variableName} = @answer;
   my $i = 0;
   indent($indentLevel);
   print "\$$variableName = ";
   foreach $word (@answer){
      if ($word =~ /int\(/){
         if ($word =~ /sys.stdin.readline\(\)/){
            $word =~ s/sys\.stdin\.readline\(\)/\<STDIN\>/;
         } 
         print "$word";
      } elsif ($word =~ /sys.stdin.readline\(\)/){
         print "\<STDIN\>";
      } elsif ($word eq "and"){
         print "$word";
      } elsif ($word eq "or"){
         print "$word";
      } elsif ($word eq "not"){
         print "$word";
      } elsif ($word =~ /[A-Za-z]+[0-9]*/){
         print "\$$word"
      } else {
         print "$word";
      }
      if ($i < $#answer){
         print " ";
      }
      
      $i++;
   }
}

sub printWithVariables {
   #deals with printing variables that are come across
   $line = shift;
   my @answer = split(' ', $line);
   indent($indentLevel);
   #checking if variables will do arithmetic operations on
   if ($line =~ /^\s*print\s*([A-Za-z]+(,\s)?)+$/){
      print "print \"";
   } else {
      print "print ";
   }
   
   @answer = @answer[1 .. $#answer];
   my $i = 0;
   foreach my $word (@answer){
      $word =~ s/^\s*//;
      $word =~ s/,//;
      
      if ($word =~ /int\(/){
         if ($word =~ /sys.stdin.readline\(\)/){
            $word =~ s/sys\.stdin\.readline\(\)/\<STDIN\>/;
         } 
         print "$word";
      } elsif ($word eq "and"){
         print "$word";
      } elsif ($word eq "or"){
         print "$word";
      } elsif ($word =~ /not/){
         print "$word";
      } elsif ($word =~ /\[.*\]/){
         @variable = split('\[', $word);
         $variable[1] =~ s/\[//;
         $variable[1] =~ s/\]//;  
         print "\$$variable[0]\[\$$variable[1]\]";
      } elsif ($word =~ /^[A-Za-z]+[0-9]*/){
         print "\$$word";
      } else {
         print "$word";
      }
      
      if ($i < $#answer){
         print " ";
      }
      $i++;
   }
}

sub ifStatement {
   #things to do if an if statement appears, multiline or single line
   my $line = shift;
   @expression = split(':', $line);
   @condition = split(' ', $expression[0]);
   @statements = split(';', $expression[1]);
   
   @condition = @condition[1..$#condition];
   my $i = 0;
   indent($indentLevel);
   print "if \(";
   $indentLevel += 3;
   foreach $word (@condition){
      $word =~ s/^\s*//;
      if ($word =~ /int\(/){
         if ($word =~ /sys.stdin.readline\(\)/){
            $word =~ s/sys\.stdin\.readline\(\)/\<STDIN\>/;
         } 
         print "$word";
      } elsif ($word =~ /and/){
         print "$word";
      } elsif ($word =~ /or/){
         print "$word";
      } elsif ($word =~ /not/){
         print "$word";
      } elsif ($word =~ /^[A-Za-z]+[0-9]*/){
         print "\$$word";
      } else {
         print $word;
      }
      
      if ($i < $#condition){
         print " ";
      }
      $i++;
   }
}

sub whileExpression {
   #deals with multiline and single line while expressions
   my $line = shift;
   @expression = split(':', $line);
   @condition = split(' ', $expression[0]);
   @statements = split(';', $expression[1]);
   
   @condition = @condition[1..$#condition];
   my $i = 0;
   indent($indentLevel);
   print "while \(";
   $indentLevel += 3;
   foreach $word (@condition){
      $word =~ s/^\s*//;
      if ($word =~ /int\(/){
         if ($word =~ /sys.stdin.readline\(\)/){
            $word =~ s/sys\.stdin\.readline\(\)/\<STDIN\>/;
         } 
         print "$word";
      } elsif ($word =~ /and/){
         print "$word";
      } elsif ($word =~ /or/){
         print "$word";
      } elsif ($word =~ /not/){
         print "$word";
      } elsif ($word =~ /^[A-Za-z]+[0-9]*/){
         print "\$$word";
      } else {
         print $word;
      }
      
      if ($i < $#condition){
         print " ";
      }
      $i++;
   }
}

sub backIndent {
   #backindents the correct amount of spaces to ensure correct formatting
   my $line = shift;
   my $whiteSpace = $line;
   $whiteSpace =~ s/[^ ].*//;
   my $currentLevel = length($whiteSpace) - 1;
   if($currentLevel < 0){
      $currentLevel = 0;
   }
   
   #print "current level is $currentLevel, indent level is $indentLevel\n";
   
   while ($currentLevel < $indentLevel-1){
      $indentLevel -= 3;
      indent($indentLevel);
      print "\}\n";
   }
}

sub indent {
   #indents the correct amount of lines so formatting is correct
   my $i = 0;
   my $indent = shift;
   while ($i < $indent){
      print " ";
      $i++;
   }
}