package Webqq::Encryption::TEA::Perl;
use strict;
my $r = "";
my $a = 0;
my @g = ();
my @w = ();
my $x = 0;
my $t = 0;
my @l = ();
my @s = ();
my $m = 1;
sub e{
    return int(0.5+ rand() * 4294967295 );
}
sub i{
    my($B,$C,$y) = @_;
    if (!$y || $y > 4) { 
        $y = 4;
    }
    my $z = 0;
    for (my $A = $C; $A < $C + $y; $A++) {
        $z <<=  8;
        $z |= $B->[$A];
    }
    return ($z & 4294967295) >> 0;
}
sub b {
    my($z, $A, $y) = @_;
    $z->[$A + 3] = ($y >> 0) & 255;
    $z->[$A + 2] = ($y >> 8) & 255;
    $z->[$A + 1] = ($y >> 16) & 255;
    $z->[$A + 0] = ($y >> 24) & 255;
}

sub v {
    my($B) = @_;
    if(!@$B){
        return "";
    } 
    my $y = "";
    for (my $z = 0; $z < @$B; $z++) {
        my $A = sprintf "%x",$B->[$z]+0;
        if(length($A) == 1){
            $A = "0" . $A;
        }
        $y .= $A;
    }
    return $y;
}

sub u {
    my ($z) = @_;
    my $A = "";
    for( my $y =0;$y<length($z);$y+=2){
        $A .= chr(hex(substr($z,$y,2)));
    }
    return $A;
}

sub c {
    my ($A) = @_;
    if(!$A){
        return "";
    } 
    my @z;
    for (my $y = 0; $y < length($A); $y++) {
        $z[$y] = ord(substr($A,$y,1));
    }
    return v(\@z);
}
sub h{
    my ($A) = @_;
    $x = $t = 0;
    $m = 1;
    $a = 0;
    my $y = @$A;
    my $B = 0;
    $a = ($y + 10) % 8;
    $a = 8 - $a if $a!=0;
    $g[0] = ((e() & 248) | $a) & 255; 
    for (my $z = 1; $z <= $a; $z++) {
        $g[$z] = e() & 255;
    }
    $a++;
    for (my $z = 0; $z < 8; $z++) {
        $w[$z] = 0;
    }
    $B = 1;
    while ($B <= 2) {
        if ($a < 8) {
            $g[$a++] = e() & 255;
            $B++;
        }
        if ($a == 8) {
            for (my $y = 0; $y < 8; $y++) {
                if ($m) {
                    $g[$y] ^= $w[$y];
                }
                else{
                    $g[$y] ^= $l[$t + $y];
                }
            }
            my $z = j(\@g);
            for (my $y = 0; $y < 8; $y++) {
                $l[$x + $y] = $z->[$y] ^ $w[$y];
                $w[$y] = $g[$y];
            }
            $t = $x;
            $x += 8;
            $a = 0;
            $m = 0;
        }
    }
    my $z = 0;
    while ($y > 0) {
        if ($a < 8) {
            $g[$a++] = $A->[$z++];
            $y--;
        }
        if ($a == 8) {
            for (my $y = 0; $y < 8; $y++) {
                if ($m) {
                    $g[$y] ^= $w[$y];
                }
                else{
                    $g[$y] ^= $l[$t + $y];
                }
            }
            my $z = j(\@g);
            for (my $y = 0; $y < 8; $y++) {
                $l[$x + $y] = $z->[$y] ^ $w[$y];
                $w[$y] = $g[$y];
            }
            $t = $x;
            $x += 8;
            $a = 0;
            $m = 0;
        }
    }

    $B = 1;
    while ($B <= 7) {
        if ($a < 8) {
            $g[$a++] = 0;
            $B++;
        }
        if ($a == 8) {
            for (my $y = 0; $y < 8; $y++) {
                if ($m) {
                    $g[$y] ^= $w[$y];
                }
                else{
                    $g[$y] ^= $l[$t + $y];
                }
            }
            my $z = j(\@g);
            for (my $y = 0; $y < 8; $y++) {
                $l[$x + $y] = $z->[$y] ^ $w[$y];
                $w[$y] = $g[$y];
            }
            $t = $x;
            $x += 8;
            $a = 0;
            $m = 0;
        }
    }       
    return \@l;
}

sub p {
    my ($C) = @_;
    my $B = 0;
    my @z ;#length 8
    my $y = @$C; 
    @s = @$C;
    if ($y % 8 != 0 or $y < 16) {
        return undef;
    }
    @w = k($C);
    $a = $w[0] & 7;
    $B = $y - $a - 10;
    return undef if $B <0;
    for (my $A = 0; $A < 8; $A++) {
        $z[$A] = 0;
    }

    $t = 0;
    $x = 8;
    $a++;   
    my $D = 1;
    while ($D <= 2) {
        if ($a < 8) {
            $a++;
            $D++;
        }
        if ($a == 8) {
            @z = @$C;
        }
        if (!f()) {return undef}
    }

    my $A = 0;
    while ($B != 0) {
        if ($a < 8) {
            $l[$A] = ($z[$t + $a] ^ $w[$a]) & 255;
            $A++;
            $B--;
            $a++;
        }       
        if ($a == 8) {
            @z = @$C;
            $t = $x - 8;
            if (!f()) {return undef}
        }
    }

    for ($D = 1; $D < 8; $D++) {
        if ($a < 8) {
            if (($z[$t + $a] ^ $w[$a]) != 0) {
                return undef;
            }
            $a++;
        }   
        if ($a == 8) {
            @z = @$C;
            $t = $x;
            if (!f()) {return undef}
        }
    }

    return \@l;
}

sub j {
    my $A = shift;
    my $B = 16;
    my $G = i($A, 0, 4);
    my $F = i($A, 4, 4);
    my $I = i($r, 0, 4);
    my $H = i($r, 4, 4);
    my $E = i($r, 8, 4);
    my $D = i($r, 12, 4);
    my $C = 0;
    my $J = 2654435769 >> 0;
    while ($B-- > 0) {
        $C += $J;
        $C = ($C & 4294967295) >> 0;
        $G += (($F << 4) + $I) ^ ($F + $C) ^ (($F >> 5) + $H);
        $G = ($G & 4294967295) >> 0;
        $F += (($G << 4) + $E) ^ ($G + $C) ^ (($G >> 5) + $D);
        $F = ($F & 4294967295) >> 0
    }
    my @K;
    b(\@K, 0, $G);
    b(\@K, 4, $F);
    return \@K;
}

sub k {
    my $A = shift;
    my $B = 16;
    my $G = i($A, 0, 4);
    my $F = i($A, 4, 4);
    my $I = i($r, 0, 4);
    my $H = i($r, 4, 4);
    my $E = i($r, 8, 4);
    my $D = i($r, 12, 4);
    my $C = 3816266640 >> 0;
    my $J = 2654435769 >> 0;
    while ($B-- > 0) {
        $F -= (($G << 4) + $E) ^ ($G + $C) ^ (($G >> 5) + $D);
        $F = ($F & 4294967295) >> 0;
        $G -= (($F << 4) +$I) ^ ($F + $C) ^ (($F >> 5) + $H);
        $G = ($G & 4294967295) >> 0;
        $C -= $J;
        $C = ($C & 4294967295) >> 0
    }
    my @K;
    b(\@K, 0, $G);
    b(\@K, 4, $F);
    return \@K
}

sub f {
    my $y = @s;
    for (my $z = 0; $z < 8; $z++) {
        $w[$z] ^= $s[$x + $z]
    }
    @w = k(\@w);
    $x += 8;
    $a = 0;
    return 1;
}

sub n{
    my($C,$B) = @_;
    my @A;
    if ($B) {
        for (my $z = 0; $z < length($C); $z++) {
            $A[$z] = ord(substr($C,$z,1)) & 255;
        }
    } else {
        my $y = 0;
        for (my $z = 0; $z < length($C); $z += 2) {
            $A[$y++] =  hex(substr($C,$z,2));
        }
    }
    return \@A;
}

sub encrypt {
    my($key,$data) = @_;
    $r = n($key); 
    my $B = n($data);
    my $A = h($B);
    my $y = "";
    for (my $z = 0; $z < @$A; $z++) {
        $y .= chr($A->[$z]);
    }
    return $y;
}
1;
