package Webqq::Client::Plugin;
sub new{
    bless {
        plugin_num          => 0,
        plugins             =>  {},
    };
}

sub load {
    my $self = shift;
    my @module_name = @_;
    for my $module_name (@module_name){
        my $module_function = undef;
        if(substr($module_name,0,1) eq '+'){
            substr($module_name,0,1) = "";
            $module = $module_name;
        }
        else{
            $module = "Webqq::Client::Plugin::" . $module_name;
        }
        eval "require $module";
        die "加载插件[ $module ]失败: $@\n" if $@;
        $module_function = *{"${module}::call"}{CODE};
        die "加载插件[ $module ]失败: 未获取到call函数引用\n" if ref $module_function ne 'CODE';
        $self->{plugin_num}++;
        $self->{plugins}{$module_name} = {
            id=>$self->{plugin_num},
            code=>$module_function,
        };
    }
}

sub call_all{
    my $self = shift;
    for(sort {$self->{plugins}{$a}{id}<=>$self->{plugins}{$b}{id}} keys  %{$self->{plugins}}){
        &{$self->{plugins}{$_}{code}}($self,@_);
    }
}

sub call{
    my $self = shift;
    my @plugins;
    if(ref $_[0] eq 'ARRAY'){
        @plugins = @{$_[0]};
        shift;
    }
    else{
        push @plugins,$_[0];
        shift;
    }

    for(@plugins){
        if(exists $self->{plugins}{$_}){
            eval {
                &{$self->{plugins}{$_}{code}}($self,@_);   
            };
            print $@,"\n" if $@;            
        }
        else{
            die "运行插件[ $_ ]失败：找不到该插件\n"; 
        }
    }
}

sub plugin{
    my $self = shift;
    my $plugin = shift;
    if(exists $self->{plugins}{$plugin}){
        return $self->{plugins}{$plugin}{code};
    }
    else{
        die "查找插件[ $_ ]失败：找不到该插件\n";
    }
}

sub clear {
    my $self = shift;
    $self->{plugins} = [];
}
1;
