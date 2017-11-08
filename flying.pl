#!/usr/bin/perl
# Screensaver main routine
use Gtk2 qw/-init/;
use Cairo;
use POSIX qw/ceil/;
use constant {SX => 0, SY => 1, SZ => 2, COLOR => 3};
use warnings;
use strict;

$SIG{__WARN__} = sub {print "WARN: $_[0]\n"};
$SIG{__DIE__} = sub {print "DIE: $_[0]\n"};

my @colors = map { lookup_color($_) }
('white',   # white
 '#c3c7cb', # light gray
 '#aa0055', # burgundy
 '#aa55aa', # lavender
 '#55aaaa', # teal blue
 '#00ff00', # bright green
 '#aaaa55', # tan
 '#00aa55', # teal green
 '#ff0000', # red
 '#0000aa', # blue
 '#868a8e', # some other gray
);

my $nobjects = 20;
my $speed = 15;
my $realspeed = 0;
my $mode = 1;
my @objects = ();

while ( my $x = shift @ARGV ) {
    if ( $x =~ m/^-r/ or $x =~ m/^-w/ ) { }
    elsif ( $x =~ m/^-n/ ) { $nobjects = shift(@ARGV)+0 }
    elsif ( $x =~ m/^-s/ ) { $speed = shift(@ARGV)/10+10 }
    elsif ( $x =~ m/^-m/ ) { $mode = shift(@ARGV)+0 }
    elsif ( $x =~ m/^-[h?]/ ) {
        print STDERR "Usage: $0 [-root] [-window] [-n NUMBER] [-speed SPEED] [-mode MODE]\nWhere NUMBER is number of items default 20, SPEED is 10-20 default 15";
        exit 1;
    }
}
$speed = 50 if $speed > 50;
$speed = 1 if $speed < 1;
$nobjects = 1 if $nobjects < 1;

resetState();
exit(main());

sub newObject {
    my ($i) = @_;
    my $r = rand()*1000+50;
    my $theta = rand()*2*3.14159;
    $objects[$i] = [$r*cos($theta), $r*sin($theta), rand()*300+10,
                    $colors[$mode?int(rand()*@colors):0]];
}

sub resetState {
  @objects = ();
  newObject(scalar @objects) while @objects < $nobjects;
  $realspeed = 0;
}
sub draw {
    my ($cr,$w,$h) = @_;
    my $size = $w < $h ? $w : $h;
    my ($screenw,$screenh) = ($w/2,$h/2);
    my $radius = $size/2.1;

    # Background
    $cr->set_source_rgb(0,0,0);
    $cr->paint();

    # Install new items in the objects array
    my $scale = sqrt($screenw*$screenw+$screenh*$screenh);
    for ( my $i = 0; $i < @objects; $i++ ) {
        $cr->set_source_rgb(@{$objects[$i][COLOR]});
        my $ratio = 25/$objects[$i][SZ];
        my $size = 120/$objects[$i][SZ]+1;
        my $screenx = $objects[$i][SX]*$ratio+$screenw;
        my $screeny = $objects[$i][SY]*$ratio+$screenh;
        if ( $mode ) {
            winlogo($cr, $screenx, $screeny, min(($size-1)/15,75/188));
            $cr->fill();
        }
        else {
            $size = ceil($size);
            $cr->rectangle($screenx, $screeny, $size, $size);
        }
        $objects[$i][SZ] -= $realspeed;
        $realspeed += .02 if $realspeed < $speed;
        newObject($i) if $objects[$i][SZ] <= 0;
    }
    #setTimeout('draw()',90-speed);
    $cr->fill() unless $mode;
    $cr->show_page;
}

# New helper functions

sub min {
    my ($a,$b) = @_;
    return $a<$b ? $a : $b;
}

sub lookup_color {
    my ($c) = @_;
    my $color = Gtk2::Gdk::Color->parse($c);
    return [$color->red/65535, $color->green/65535, $color->blue/65535];
}

# GTK stuff
sub main {
    my $window;
    my $interval = 90-$speed;
    if ( $ENV{XSCREENSAVER_WINDOW} ) {
        print "$ENV{XSCREENSAVER_WINDOW}\n";
        $window = Gtk2::Gdk::Window->foreign_new(hex($ENV{XSCREENSAVER_WINDOW}));
        Glib::Timeout->add($interval, sub { RenderCaller($window); 1});
    }
    else {
        $window = Gtk2::Window->new('toplevel');
        $window->resize(800,600);
        $window->set_title($mode ? 'Flying Windows' : 'Starfield Simulation');
        $window->signal_connect('expose-event',\&expose);
        $window->signal_connect('configure-event',\&configure);
        $window->signal_connect('destroy', sub { Gtk2->main_quit });
        $window->set_app_paintable(1);
        $window->show_all();
        Glib::Timeout->add($interval, sub { $window->window->invalidate_rect($window->allocation,0); 1});
    }
    Gtk2->main;
    return 0;
}

sub configure {
    my ($window) = @_;
    $window->window->invalidate_rect($window->allocation,0) if $window;
}

sub expose {
    my ($window) = @_;
    RenderCaller($window->window);
}

sub RenderCaller {
    my ($window) = @_;
    my @allocation = $window->get_geometry;
    my $pixmap = Gtk2::Gdk::Pixmap->new($window,$allocation[2],$allocation[3],-1); # Irritating
    my $cr = Gtk2::Gdk::Cairo::Context->create($pixmap);
    draw($cr,$allocation[2],$allocation[3]);
    $window->draw_drawable(Gtk2::Gdk::GC->new($window),$pixmap,0,0,0,0,$allocation[2],$allocation[3]);
}

# Windows Logo (TM Microsoft)

sub winlogo {
    my ($cr,$x,$y,$scale) = @_;
    $cr->new_path();
    $cr->move_to($x+$scale*6.039995,$y+$scale*16.608544);
    $cr->line_to($x+$scale*-0.000005,$y+$scale*19.298544);
    $cr->line_to($x+$scale*-0.000005,$y+$scale*13.787544);
    $cr->line_to($x+$scale*6.039995,$y+$scale*10.698544);
    $cr->line_to($x+$scale*6.039995,$y+$scale*16.608544);
    $cr->move_to($x+$scale*6.039995,$y+$scale*35.818544);
    $cr->line_to($x+$scale*-0.000005,$y+$scale*38.508544);
    $cr->line_to($x+$scale*-0.000005,$y+$scale*32.868544);
    $cr->line_to($x+$scale*6.039995,$y+$scale*29.908544);
    $cr->line_to($x+$scale*6.039995,$y+$scale*35.818544);
    $cr->move_to($x+$scale*6.039995,$y+$scale*54.227544);
    $cr->line_to($x+$scale*-0.000005,$y+$scale*56.778544);
    $cr->line_to($x+$scale*-0.000005,$y+$scale*51.138544);
    $cr->line_to($x+$scale*6.039995,$y+$scale*48.318544);
    $cr->line_to($x+$scale*6.039995,$y+$scale*54.227544);
    $cr->move_to($x+$scale*6.039995,$y+$scale*73.168544);
    $cr->line_to($x+$scale*-0.000005,$y+$scale*75.858544);
    $cr->line_to($x+$scale*-0.000005,$y+$scale*70.218544);
    $cr->line_to($x+$scale*6.039995,$y+$scale*67.258544);
    $cr->line_to($x+$scale*6.039995,$y+$scale*73.168544);
    $cr->move_to($x+$scale*6.039995,$y+$scale*92.388544);
    $cr->line_to($x+$scale*-0.000005,$y+$scale*95.068544);
    $cr->line_to($x+$scale*-0.000005,$y+$scale*89.568544);
    $cr->line_to($x+$scale*6.039995,$y+$scale*86.608544);
    $cr->line_to($x+$scale*6.039995,$y+$scale*92.388544);
    $cr->move_to($x+$scale*6.039995,$y+$scale*110.787544);
    $cr->line_to($x+$scale*-0.000005,$y+$scale*113.477544);
    $cr->line_to($x+$scale*-0.000005,$y+$scale*107.968544);
    $cr->line_to($x+$scale*6.039995,$y+$scale*105.017544);
    $cr->line_to($x+$scale*6.039995,$y+$scale*110.787544);
    $cr->move_to($x+$scale*6.039995,$y+$scale*129.868544);
    $cr->line_to($x+$scale*-0.000005,$y+$scale*132.558544);
    $cr->line_to($x+$scale*-0.000005,$y+$scale*127.048544);
    $cr->line_to($x+$scale*6.039995,$y+$scale*123.958544);
    $cr->line_to($x+$scale*6.039995,$y+$scale*129.868544);
    $cr->move_to($x+$scale*21.089995,$y+$scale*21.718544);
    $cr->line_to($x+$scale*13.299995,$y+$scale*26.148544);
    $cr->line_to($x+$scale*13.299995,$y+$scale*18.218544);
    $cr->line_to($x+$scale*21.089995,$y+$scale*13.517544);
    $cr->line_to($x+$scale*21.089995,$y+$scale*21.718544);
    $cr->move_to($x+$scale*21.089995,$y+$scale*41.058544);
    $cr->line_to($x+$scale*13.299995,$y+$scale*45.358544);
    $cr->line_to($x+$scale*13.299995,$y+$scale*37.437544);
    $cr->line_to($x+$scale*21.089995,$y+$scale*32.727544);
    $cr->line_to($x+$scale*21.089995,$y+$scale*41.058544);
    $cr->move_to($x+$scale*21.089995,$y+$scale*59.338544);
    $cr->line_to($x+$scale*13.299995,$y+$scale*63.767544);
    $cr->line_to($x+$scale*13.299995,$y+$scale*55.707544);
    $cr->line_to($x+$scale*21.089995,$y+$scale*51.008544);
    $cr->line_to($x+$scale*21.089995,$y+$scale*59.338544);
    $cr->move_to($x+$scale*21.089995,$y+$scale*78.408544);
    $cr->line_to($x+$scale*13.299995,$y+$scale*82.848544);
    $cr->line_to($x+$scale*13.299995,$y+$scale*74.787544);
    $cr->line_to($x+$scale*21.089995,$y+$scale*70.078544);
    $cr->line_to($x+$scale*21.089995,$y+$scale*78.408544);
    $cr->move_to($x+$scale*21.089995,$y+$scale*97.628544);
    $cr->line_to($x+$scale*13.299995,$y+$scale*102.058544);
    $cr->line_to($x+$scale*13.299995,$y+$scale*94.128544);
    $cr->line_to($x+$scale*21.089995,$y+$scale*89.428544);
    $cr->line_to($x+$scale*21.089995,$y+$scale*97.628544);
    $cr->move_to($x+$scale*21.089995,$y+$scale*116.028544);
    $cr->line_to($x+$scale*13.299995,$y+$scale*120.468544);
    $cr->line_to($x+$scale*13.299995,$y+$scale*112.398544);
    $cr->line_to($x+$scale*21.089995,$y+$scale*107.698544);
    $cr->line_to($x+$scale*21.089995,$y+$scale*116.028544);
    $cr->move_to($x+$scale*21.089995,$y+$scale*135.107544);
    $cr->line_to($x+$scale*13.299995,$y+$scale*139.408544);
    $cr->line_to($x+$scale*13.299995,$y+$scale*131.477544);
    $cr->line_to($x+$scale*21.089995,$y+$scale*126.777544);
    $cr->line_to($x+$scale*21.089995,$y+$scale*135.107544);
    $cr->move_to($x+$scale*38.559995,$y+$scale*29.238544);
    $cr->line_to($x+$scale*27.809995,$y+$scale*34.078544);
    $cr->line_to($x+$scale*27.809995,$y+$scale*24.537544);
    $cr->line_to($x+$scale*38.559995,$y+$scale*19.428544);
    $cr->line_to($x+$scale*38.559995,$y+$scale*29.238544);
    $cr->move_to($x+$scale*38.559995,$y+$scale*48.448544);
    $cr->line_to($x+$scale*27.809995,$y+$scale*53.287544);
    $cr->line_to($x+$scale*27.809995,$y+$scale*43.747544);
    $cr->line_to($x+$scale*38.559995,$y+$scale*38.648544);
    $cr->line_to($x+$scale*38.559995,$y+$scale*48.448544);
    $cr->move_to($x+$scale*38.559995,$y+$scale*66.727544);
    $cr->line_to($x+$scale*27.809995,$y+$scale*71.558544);
    $cr->line_to($x+$scale*27.809995,$y+$scale*62.017544);
    $cr->line_to($x+$scale*38.559995,$y+$scale*56.778544);
    $cr->line_to($x+$scale*38.559995,$y+$scale*66.727544);
    $cr->move_to($x+$scale*38.559995,$y+$scale*85.798544);
    $cr->line_to($x+$scale*27.809995,$y+$scale*90.638544);
    $cr->line_to($x+$scale*27.809995,$y+$scale*81.098544);
    $cr->line_to($x+$scale*38.559995,$y+$scale*75.988544);
    $cr->line_to($x+$scale*38.559995,$y+$scale*85.798544);
    $cr->move_to($x+$scale*38.559995,$y+$scale*105.017544);
    $cr->line_to($x+$scale*27.809995,$y+$scale*109.988544);
    $cr->line_to($x+$scale*27.809995,$y+$scale*100.308544);
    $cr->line_to($x+$scale*38.559995,$y+$scale*95.207544);
    $cr->line_to($x+$scale*38.559995,$y+$scale*105.017544);
    $cr->move_to($x+$scale*38.559995,$y+$scale*123.418544);
    $cr->line_to($x+$scale*27.809995,$y+$scale*128.388544);
    $cr->line_to($x+$scale*27.809995,$y+$scale*118.718544);
    $cr->line_to($x+$scale*38.559995,$y+$scale*113.608544);
    $cr->line_to($x+$scale*38.559995,$y+$scale*123.418544);
    $cr->move_to($x+$scale*38.559995,$y+$scale*142.498544);
    $cr->line_to($x+$scale*27.809995,$y+$scale*147.338544);
    $cr->line_to($x+$scale*27.809995,$y+$scale*137.798544);
    $cr->line_to($x+$scale*38.559995,$y+$scale*132.687544);
    $cr->line_to($x+$scale*38.559995,$y+$scale*142.498544);
    $cr->move_to($x+$scale*56.429995,$y+$scale*30.848544);
    $cr->line_to($x+$scale*43.259995,$y+$scale*37.168544);
    $cr->line_to($x+$scale*43.259995,$y+$scale*23.868544);
    $cr->line_to($x+$scale*56.429995,$y+$scale*17.687544);
    $cr->line_to($x+$scale*56.429995,$y+$scale*30.848544);
    $cr->move_to($x+$scale*56.429995,$y+$scale*50.198544);
    $cr->line_to($x+$scale*43.259995,$y+$scale*56.508544);
    $cr->line_to($x+$scale*43.259995,$y+$scale*43.207544);
    $cr->line_to($x+$scale*56.429995,$y+$scale*36.898544);
    $cr->line_to($x+$scale*56.429995,$y+$scale*50.198544);
    $cr->move_to($x+$scale*56.429995,$y+$scale*68.468544);
    $cr->line_to($x+$scale*43.259995,$y+$scale*74.787544);
    $cr->line_to($x+$scale*43.259995,$y+$scale*61.477544);
    $cr->line_to($x+$scale*56.429995,$y+$scale*55.308544);
    $cr->line_to($x+$scale*56.429995,$y+$scale*68.468544);
    $cr->move_to($x+$scale*56.429995,$y+$scale*87.548544);
    $cr->line_to($x+$scale*43.259995,$y+$scale*93.858544);
    $cr->line_to($x+$scale*43.259995,$y+$scale*80.558544);
    $cr->line_to($x+$scale*56.429995,$y+$scale*74.378544);
    $cr->line_to($x+$scale*56.429995,$y+$scale*87.548544);
    $cr->move_to($x+$scale*56.429995,$y+$scale*106.898544);
    $cr->line_to($x+$scale*43.259995,$y+$scale*113.207544);
    $cr->line_to($x+$scale*43.259995,$y+$scale*99.908544);
    $cr->line_to($x+$scale*56.429995,$y+$scale*93.598544);
    $cr->line_to($x+$scale*56.429995,$y+$scale*106.898544);
    $cr->move_to($x+$scale*56.429995,$y+$scale*125.168544);
    $cr->line_to($x+$scale*43.259995,$y+$scale*131.348544);
    $cr->line_to($x+$scale*43.259995,$y+$scale*118.178544);
    $cr->line_to($x+$scale*56.429995,$y+$scale*111.868544);
    $cr->line_to($x+$scale*56.429995,$y+$scale*125.168544);
    $cr->move_to($x+$scale*56.429995,$y+$scale*144.107544);
    $cr->line_to($x+$scale*43.259995,$y+$scale*150.428544);
    $cr->line_to($x+$scale*43.259995,$y+$scale*137.128544);
    $cr->line_to($x+$scale*56.429995,$y+$scale*130.947544);
    $cr->line_to($x+$scale*56.429995,$y+$scale*144.107544);
    $cr->move_to($x+$scale*75.369995,$y+$scale*31.787544);
    $cr->line_to($x+$scale*59.919995,$y+$scale*39.588544);
    $cr->line_to($x+$scale*59.919995,$y+$scale*24.537544);
    $cr->line_to($x+$scale*75.369995,$y+$scale*16.738544);
    $cr->line_to($x+$scale*75.369995,$y+$scale*31.787544);
    $cr->move_to($x+$scale*75.369995,$y+$scale*51.008544);
    $cr->line_to($x+$scale*59.919995,$y+$scale*58.798544);
    $cr->line_to($x+$scale*59.919995,$y+$scale*43.747544);
    $cr->line_to($x+$scale*75.369995,$y+$scale*35.957544);
    $cr->line_to($x+$scale*75.369995,$y+$scale*51.008544);
    $cr->move_to($x+$scale*75.369995,$y+$scale*69.278544);
    $cr->line_to($x+$scale*59.919995,$y+$scale*77.068544);
    $cr->line_to($x+$scale*59.919995,$y+$scale*62.017544);
    $cr->line_to($x+$scale*75.369995,$y+$scale*54.227544);
    $cr->line_to($x+$scale*75.369995,$y+$scale*69.278544);
    $cr->move_to($x+$scale*75.369995,$y+$scale*88.358544);
    $cr->line_to($x+$scale*59.919995,$y+$scale*96.278544);
    $cr->line_to($x+$scale*59.919995,$y+$scale*81.098544);
    $cr->line_to($x+$scale*75.369995,$y+$scale*73.308544);
    $cr->line_to($x+$scale*75.369995,$y+$scale*88.358544);
    $cr->move_to($x+$scale*75.369995,$y+$scale*107.568544);
    $cr->line_to($x+$scale*59.919995,$y+$scale*115.497544);
    $cr->line_to($x+$scale*59.919995,$y+$scale*100.308544);
    $cr->line_to($x+$scale*75.369995,$y+$scale*92.517544);
    $cr->line_to($x+$scale*75.369995,$y+$scale*107.568544);
    $cr->move_to($x+$scale*75.369995,$y+$scale*125.968544);
    $cr->line_to($x+$scale*59.919995,$y+$scale*133.897544);
    $cr->line_to($x+$scale*59.919995,$y+$scale*118.718544);
    $cr->line_to($x+$scale*75.369995,$y+$scale*110.928544);
    $cr->line_to($x+$scale*75.369995,$y+$scale*125.968544);
    $cr->move_to($x+$scale*75.369995,$y+$scale*145.048544);
    $cr->line_to($x+$scale*59.919995,$y+$scale*152.838544);
    $cr->line_to($x+$scale*59.919995,$y+$scale*137.798544);
    $cr->line_to($x+$scale*75.369995,$y+$scale*130.008544);
    $cr->line_to($x+$scale*75.369995,$y+$scale*145.048544);
    $cr->move_to($x+$scale*95.388995,$y+$scale*26.687544);
    $cr->line_to($x+$scale*78.729995,$y+$scale*35.418544);
    $cr->line_to($x+$scale*78.729995,$y+$scale*18.758544);
    $cr->line_to($x+$scale*95.388995,$y+$scale*10.698544);
    $cr->line_to($x+$scale*95.388995,$y+$scale*26.687544);
    $cr->move_to($x+$scale*95.388995,$y+$scale*45.767544);
    $cr->line_to($x+$scale*78.729995,$y+$scale*54.497544);
    $cr->line_to($x+$scale*78.729995,$y+$scale*37.838544);
    $cr->line_to($x+$scale*95.388995,$y+$scale*29.638544);
    $cr->line_to($x+$scale*95.388995,$y+$scale*45.767544);
    $cr->move_to($x+$scale*95.388995,$y+$scale*64.707544);
    $cr->line_to($x+$scale*78.729995,$y+$scale*73.308544);
    $cr->line_to($x+$scale*78.729995,$y+$scale*56.648544);
    $cr->line_to($x+$scale*95.388995,$y+$scale*48.588544);
    $cr->line_to($x+$scale*95.388995,$y+$scale*64.707544);
    $cr->move_to($x+$scale*95.388995,$y+$scale*83.648544);
    $cr->line_to($x+$scale*78.729995,$y+$scale*92.388544);
    $cr->line_to($x+$scale*78.729995,$y+$scale*75.727544);
    $cr->line_to($x+$scale*95.388995,$y+$scale*67.658544);
    $cr->line_to($x+$scale*95.388995,$y+$scale*83.648544);
    $cr->move_to($x+$scale*95.388995,$y+$scale*102.457544);
    $cr->line_to($x+$scale*78.729995,$y+$scale*111.058544);
    $cr->line_to($x+$scale*78.729995,$y+$scale*94.537544);
    $cr->line_to($x+$scale*95.388995,$y+$scale*86.338544);
    $cr->line_to($x+$scale*95.388995,$y+$scale*102.457544);
    $cr->move_to($x+$scale*95.388995,$y+$scale*121.937544);
    $cr->line_to($x+$scale*78.729995,$y+$scale*130.538544);
    $cr->line_to($x+$scale*78.729995,$y+$scale*113.878544);
    $cr->line_to($x+$scale*95.388995,$y+$scale*105.818544);
    $cr->line_to($x+$scale*95.388995,$y+$scale*121.937544);
    $cr->move_to($x+$scale*95.388995,$y+$scale*140.888544);
    $cr->line_to($x+$scale*78.729995,$y+$scale*149.618544);
    $cr->line_to($x+$scale*78.729995,$y+$scale*132.958544);
    $cr->line_to($x+$scale*95.388995,$y+$scale*124.897544);
    $cr->line_to($x+$scale*95.388995,$y+$scale*140.888544);
    $cr->move_to($x+$scale*182.579995,$y+$scale*144.918544);
    $cr->line_to($x+$scale*181.638995,$y+$scale*144.918544);
    $cr->line_to($x+$scale*181.638995,$y+$scale*147.468544);
    $cr->line_to($x+$scale*181.239995,$y+$scale*147.468544);
    $cr->line_to($x+$scale*181.239995,$y+$scale*144.918544);
    $cr->line_to($x+$scale*180.159995,$y+$scale*144.918544);
    $cr->line_to($x+$scale*180.159995,$y+$scale*144.508544);
    $cr->line_to($x+$scale*182.579995,$y+$scale*144.508544);
    $cr->line_to($x+$scale*182.579995,$y+$scale*144.918544);
    $cr->move_to($x+$scale*183.259995,$y+$scale*144.508544);
    $cr->line_to($x+$scale*183.928995,$y+$scale*144.508544);
    $cr->line_to($x+$scale*184.869995,$y+$scale*146.798544);
    $cr->line_to($x+$scale*185.669995,$y+$scale*144.508544);
    $cr->line_to($x+$scale*186.479995,$y+$scale*144.508544);
    $cr->line_to($x+$scale*186.479995,$y+$scale*147.468544);
    $cr->line_to($x+$scale*185.939995,$y+$scale*147.468544);
    $cr->line_to($x+$scale*185.939995,$y+$scale*145.048544);
    $cr->line_to($x+$scale*185.138995,$y+$scale*147.468544);
    $cr->line_to($x+$scale*184.598995,$y+$scale*147.468544);
    $cr->line_to($x+$scale*183.659995,$y+$scale*145.048544);
    $cr->line_to($x+$scale*183.659995,$y+$scale*147.468544);
    $cr->line_to($x+$scale*183.259995,$y+$scale*147.468544);
    $cr->line_to($x+$scale*183.259995,$y+$scale*144.508544);
    $cr->move_to($x+$scale*187.549985,$y+$scale*10.968544);
    $cr->line_to($x+$scale*187.549985,$y+$scale*141.828554);
    $cr->curve_to($x+$scale*156.249985,$y+$scale*126.647554,$x+$scale*126.289995,$y+$scale*125.027554,$x+$scale*98.070995,$y+$scale*141.428554);
    $cr->line_to($x+$scale*98.070995,$y+$scale*122.688554);
    $cr->curve_to($x+$scale*107.179985,$y+$scale*118.418554,$x+$scale*117.340985,$y+$scale*115.618554,$x+$scale*127.900985,$y+$scale*113.748554);
    $cr->line_to($x+$scale*127.900985,$y+$scale*73.978544);
    $cr->curve_to($x+$scale*118.940985,$y+$scale*74.648544,$x+$scale*109.040985,$y+$scale*77.048544,$x+$scale*98.070995,$y+$scale*82.378544);
    $cr->line_to($x+$scale*98.070995,$y+$scale*69.348544);
    $cr->curve_to($x+$scale*107.969985,$y+$scale*64.818544,$x+$scale*117.870985,$y+$scale*61.748544,$x+$scale*127.900985,$y+$scale*60.948544);
    $cr->line_to($x+$scale*127.900985,$y+$scale*19.298544);
    $cr->curve_to($x+$scale*119.469985,$y+$scale*19.838544,$x+$scale*109.830995,$y+$scale*22.638544,$x+$scale*98.070995,$y+$scale*27.838544);
    $cr->line_to($x+$scale*98.070995,$y+$scale*9.488544);
    $cr->curve_to($x+$scale*126.829995,$y+$scale*-3.002456,$x+$scale*156.519985,$y+$scale*-3.812456,$x+$scale*187.549985,$y+$scale*10.968544);
    $cr->move_to($x+$scale*169.149985,$y+$scale*117.508554);
    $cr->line_to($x+$scale*169.149985,$y+$scale*76.128544);
    $cr->curve_to($x+$scale*159.338985,$y+$scale*72.228544,$x+$scale*149.399985,$y+$scale*71.018544,$x+$scale*139.588985,$y+$scale*72.228544);
    $cr->line_to($x+$scale*139.588985,$y+$scale*113.208554);
    $cr->curve_to($x+$scale*151.009985,$y+$scale*112.668554,$x+$scale*159.739985,$y+$scale*114.418554,$x+$scale*169.149985,$y+$scale*117.508554);
    $cr->move_to($x+$scale*169.149985,$y+$scale*64.168544);
    $cr->line_to($x+$scale*169.149985,$y+$scale*22.118544);
    $cr->curve_to($x+$scale*159.338985,$y+$scale*17.958544,$x+$scale*149.399985,$y+$scale*16.478544,$x+$scale*139.588985,$y+$scale*17.418544);
    $cr->line_to($x+$scale*139.588985,$y+$scale*60.008544);
    $cr->line_to($x+$scale*151.408985,$y+$scale*60.008544);
    $cr->curve_to($x+$scale*156.649985,$y+$scale*60.008544,$x+$scale*165.249985,$y+$scale*62.687544,$x+$scale*169.149985,$y+$scale*64.168544);
    $cr->fill();
}
