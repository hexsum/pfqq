package Webqq::Encryption::TEA;
use strict;
use Carp;
use JE;

BEGIN{
    eval{require MIME::Base64;};
    unless($@){ 
        $Webqq::Encryption::TEA::has_mime_base64 = 1 ;
        *Webqq::Encryption::TEA::encode_base64 = *MIME::Base64::encode_base64;
    }
}

sub strToBytes{
    my $str = shift;
    #$str = join "",map {"\\x$_"} unpack "H2"x length($str),$str;
    my $return = "";   
    for(split //,$str){$return .= sprintf "%02x",ord($_)};
    #my $je;
    #if(defined $Webqq::Encryption::TEA::_je ){
    #    $je = $Webqq::Encryption::TEA::_je ;
    #}
    #else{
    #    my $javascript;
    #    if(defined $Webqq::Encryption::TEA::_javascript){
    #        $javascript = $Webqq::Encryption::TEA::_javascript;
    #    }
    #    else{
    #        local $/ = undef;
    #        $javascript = <DATA>;
    #        $Webqq::Encryption::TEA::_javascript = $javascript;
    #        close DATA;
    #    }
    #    $je = JE->new;
    #    $je->eval($javascript);
    #    croak "Webqq::Encryption::TEA load javascript error: $@\n" if $@;
    #    $Webqq::Encryption::TEA::_je = $je;
    #}  
    
    #print qq#
    #    var tea = TEA();
    #    var r = tea.strToBytes('$str');
    #    return(r);
    ##;
    #$return = $je->eval(qq#
    #    var tea = TEA();
    #    var r = tea.strToBytes('$str');
    #    return(r);
    ##);

    #croak $@ if $@;
    return $return;
}
sub encrypt {
    my ($key,$data) = @_;
    $key = join "",map {"\\x$_"} unpack "H2"x length($key),$key;
    my $je;
    if(defined $Webqq::Encryption::TEA::_je ){
        $je = $Webqq::Encryption::TEA::_je ;
    }
    else{
        my $javascript;
        if(defined $Webqq::Encryption::TEA::_javascript){
            $javascript = $Webqq::Encryption::TEA::_javascript; 
        }
        else{
            local $/ = undef;
            $javascript = <DATA>;
            $Webqq::Encryption::TEA::_javascript = $javascript;
            close DATA;
        }
        $je = JE->new;
        $je->eval($javascript);
        croak "Webqq::Encryption::TEA load javascript error: $@\n" if $@;
        $Webqq::Encryption::TEA::_je = $je;
    }

    #print qq#
    #    var tea = TEA();
    #    tea.initkey('$key');
    #    //var r = tea.enWithoutBase64('$data');
    #    var r = tea.enAsBase64("$data");
    #    tea.initkey("");
    #    return(r);
    ##;
    my $js_code = $Webqq::Encryption::TEA::has_mime_base64?
                    "var r = tea.enWithoutBase64('$data')"
                :   "var r = tea.enAsBase64('$data')"
    ; 
    my $p = $je->eval(qq#
        var tea = TEA();
        tea.initkey('$key');
        $js_code;
        tea.initkey("");
        return(r);
    #);
    if($p and !$@){
        return $Webqq::Encryption::TEA::has_mime_base64?encode_base64($p,""):$p;
    }
    else{
        croak "Webqq::Encryption::TEA error: $@\n";
    }
}
1;
__DATA__
function TEA() {
    var r = "",
    a = 0,
    g = [],
    w = [],
    x = 0,
    t = 0,
    l = [],
    s = [],
    m = true;
    function e() {
        return Math.round(Math.random() * 4294967295)
    }
    function i(B, C, y) {
        if (!y || y > 4) {
            y = 4
        }
        var z = 0;
        for (var A = C; A < C + y; A++) {
            z <<= 8;
            z |= B[A]
        }
        return (z & 4294967295) >>> 0
    }
    function b(z, A, y) {
        z[A + 3] = (y >> 0) & 255;
        z[A + 2] = (y >> 8) & 255;
        z[A + 1] = (y >> 16) & 255;
        z[A + 0] = (y >> 24) & 255
    }
    function v(B) {
        if (!B) {
            return ""
        }
        var y = "";
        for (var z = 0; z < B.length; z++) {
            var A = Number(B[z]).toString(16);
            if (A.length == 1) {
                A = "0" + A
            }
            y += A
        }
        return y
    }
    function u(z) {
        var A = "";
        for (var y = 0; y < z.length; y += 2) {
            A += String.fromCharCode(parseInt(z.substr(y, 2), 16))
        }
        return A
    }
    function c(A) {
        if (!A) {
            return ""
        }
        var z = [];
        for (var y = 0; y < A.length; y++) {
            z[y] = A.charCodeAt(y)
        }
        return v(z)
    }
    function h(A) {
        g = new Array(8);
        w = new Array(8);
        x = t = 0;
        m = true;
        a = 0;
        var y = A.length;
        var B = 0;
        a = (y + 10) % 8;
        if (a != 0) {
            a = 8 - a
        }
        l = new Array(y + a + 10);
        g[0] = ((e() & 248) | a) & 255;
        for (var z = 1; z <= a; z++) {
            g[z] = e() & 255
        }
        a++;
        for (var z = 0; z < 8; z++) {
            w[z] = 0
        }
        B = 1;
        while (B <= 2) {
            if (a < 8) {
                g[a++] = e() & 255;
                B++
            }
            if (a == 8) {
                o()
            }
        }
        var z = 0;
        while (y > 0) {
            if (a < 8) {
                g[a++] = A[z++];
                y--
            }
            if (a == 8) {
                o()
            }
        }
        B = 1;
        while (B <= 7) {
            if (a < 8) {
                g[a++] = 0;
                B++
            }
            if (a == 8) {
                o()
            }
        }
        return l
    }
    function p(C) {
        var B = 0;
        var z = new Array(8);
        var y = C.length;
        s = C;
        if (y % 8 != 0 || y < 16) {
            return null
        }
        w = k(C);
        a = w[0] & 7;
        B = y - a - 10;
        if (B < 0) {
            return null
        }
        for (var A = 0; A < z.length; A++) {
            z[A] = 0
        }
        l = new Array(B);
        t = 0;
        x = 8;
        a++;
        var D = 1;
        while (D <= 2) {
            if (a < 8) {
                a++;
                D++
            }
            if (a == 8) {
                z = C;
                if (!f()) {
                    return null
                }
            }
        }
        var A = 0;
        while (B != 0) {
            if (a < 8) {
                l[A] = (z[t + a] ^ w[a]) & 255;
                A++;
                B--;
                a++
            }
            if (a == 8) {
                z = C;
                t = x - 8;
                if (!f()) {
                    return null
                }
            }
        }
        for (D = 1; D < 8; D++) {
            if (a < 8) {
                if ((z[t + a] ^ w[a]) != 0) {
                    return null
                }
                a++
            }
            if (a == 8) {
                z = C;
                t = x;
                if (!f()) {
                    return null
                }
            }
        }
        return l
    }
    function o() {
        for (var y = 0; y < 8; y++) {
            if (m) {
                g[y] ^= w[y]
            } else {
                g[y] ^= l[t + y]
            }
        }
        var z = j(g);
        for (var y = 0; y < 8; y++) {
            l[x + y] = z[y] ^ w[y];
            w[y] = g[y]
        }
        t = x;
        x += 8;
        a = 0;
        m = false
    }
    function j(A) {
        var B = 16;
        var G = i(A, 0, 4);
        var F = i(A, 4, 4);
        var I = i(r, 0, 4);
        var H = i(r, 4, 4);
        var E = i(r, 8, 4);
        var D = i(r, 12, 4);
        var C = 0;
        var J = 2654435769 >>> 0;
        while (B-->0) {
            C += J;
            C = (C & 4294967295) >>> 0;
            G += ((F << 4) + I) ^ (F + C) ^ ((F >>> 5) + H);
            G = (G & 4294967295) >>> 0;
            F += ((G << 4) + E) ^ (G + C) ^ ((G >>> 5) + D);
            F = (F & 4294967295) >>> 0
        }
        var K = new Array(8);
        b(K, 0, G);
        b(K, 4, F);
        return K
    }
    function k(A) {
        var B = 16;
        var G = i(A, 0, 4);
        var F = i(A, 4, 4);
        var I = i(r, 0, 4);
        var H = i(r, 4, 4);
        var E = i(r, 8, 4);
        var D = i(r, 12, 4);
        var C = 3816266640 >>> 0;
        var J = 2654435769 >>> 0;
        while (B-->0) {
            F -= ((G << 4) + E) ^ (G + C) ^ ((G >>> 5) + D);
            F = (F & 4294967295) >>> 0;
            G -= ((F << 4) + I) ^ (F + C) ^ ((F >>> 5) + H);
            G = (G & 4294967295) >>> 0;
            C -= J;
            C = (C & 4294967295) >>> 0
        }
        var K = new Array(8);
        b(K, 0, G);
        b(K, 4, F);
        return K
    }
    function f() {
        var y = s.length;
        for (var z = 0; z < 8; z++) {
            w[z] ^= s[x + z]
        }
        w = k(w);
        x += 8;
        a = 0;
        return true
    }
    function n(C, B) {
        var A = [];
        if (B) {
            for (var z = 0; z < C.length; z++) {
                A[z] = C.charCodeAt(z) & 255
            }
        } else {
            var y = 0;
            for (var z = 0; z < C.length; z += 2) {
                A[y++] = parseInt(C.substr(z, 2), 16)
            }
        }
        return A
    }

    var d = {};
    d.PADCHAR = "=";
    d.ALPHA = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    d.getbyte = function(A, z) {
        var y = A.charCodeAt(z);
        if (y > 255) {
            throw "INVALID_CHARACTER_ERR: DOM Exception 5"
        }
        return y
    };
    d.encode = function(C) {
        if (arguments.length != 1) {
            throw "SyntaxError: Not enough arguments"
        }
        var z = d.PADCHAR;
        var E = d.ALPHA;
        var D = d.getbyte;
        var B, F;
        var y = [];
        C = "" + C;
        var A = C.length - C.length % 3;
        if (C.length == 0) {
            return C
        }
        for (B = 0; B < A; B += 3) {
            F = (D(C, B) << 16) | (D(C, B + 1) << 8) | D(C, B + 2);
            y.push(E.charAt(F >> 18));
            y.push(E.charAt((F >> 12) & 63));
            y.push(E.charAt((F >> 6) & 63));
            y.push(E.charAt(F & 63))
        }
        switch (C.length - A) {
        case 1:
            F = D(C, B) << 16;
            y.push(E.charAt(F >> 18) + E.charAt((F >> 12) & 63) + z + z);
            break;
        case 2:
            F = (D(C, B) << 16) | (D(C, B + 1) << 8);
            y.push(E.charAt(F >> 18) + E.charAt((F >> 12) & 63) + E.charAt((F >> 6) & 63) + z);
            break
        }
        return y.join("")
    };

    return {
        encrypt: function(B, A) {
            var z = n(B, A);
            var y = h(z);
            return v(y)
        },
        enWithoutBase64: function(D, C) {
            var B = n(D, C);
            var A = h(B);   
            var y = "";
            for (var z = 0; z < A.length; z++) {
                y += String.fromCharCode(A[z])
            }
            return y;
        }, 
        enAsBase64: function(D, C) {
            var B = n(D, C);
            var A = h(B);
            var y = "";
            for (var z = 0; z < A.length; z++) {
                y += String.fromCharCode(A[z])
            }
            return d.encode(y)
        },
        decrypt: function(A) {
            var z = n(A, false);
            var y = p(z);
            return v(y)
        },
        initkey: function(y, z) {
            r = n(y, z)
        },
        bytesToStr: u,
        strToBytes: c,
        bytesInStr: v,
        dataFromStr: n
    }
};
