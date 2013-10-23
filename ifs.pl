#!/usr/bin/perl -w

# Inti FileServer
# ifs project - https://github.com/inticardo/ifs

# (c) 2013 - Juan Máiquez Corbalán (Inti / Int_10h) - contacto@int10h.es
# Licensed under Apache License, Version 2.0, January 2004
# http://www.apache.org/licenses/

# Last changes: 2013-10-23

# IFS is an old experiment written in Perl language. It was proposed as an 
# simple alternative to the Windows application HFS but for Linux/Unix systems. 
# The original goals were:

# - A single executable (all-in-one) file.
# - Command-line invocation application.
# - Ability to download both individual files and groups of files.

use strict;
use warnings;
use bignum;
use threads;
#use Sys::Hostname;
#use IO::Socket;
use HTTP::Daemon;
use HTTP::Status;
use HTTP::Request;
use HTTP::Response;
use HTTP::Headers;
use URI::http;
use LWP::UserAgent;
use IO::Select;
# use Data::Dumper;
use Cwd;
use File::Find;
use File::stat;
use File::Basename;
#use URI::Escape;

no warnings 'threads';

my $favicon = '47 49 46 38 39 61 10 00 10 00 80 01 00 00 77 31 FF FF FF 21 F9 04 01 0A 00 01 00 2C 00 00 00 00 10 00 10 00 00 02 25 8C 7F 00 C8 A6 DF D0 53 91 D1 55 D3 CC 0E F2 FE 75 14 37 8D 55 89 45 9B D7 94 81 A9 B2 E7 95 C6 2F DC D2 75 01 00 3B';
$favicon =~ s/ //g;
my $faviconsize = length($favicon) / 2;
$favicon = pack "H*", $favicon;

my $HTMLTEMPLATE = <<WACAMOLE;
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
	<meta content="text/html; charset=UTF-8" http-equiv="content-type" />
	<link href="__favicon__.gif" rel="shortcut icon" type="image/x-icon" />
	
	<style type="text/css">
	
	body {
		font-size: 10pt;
		font-family: sans-serif;
		background-color: #003;
		color: #FFF;
		padding: 12px;
	}
	
	h1 {
		font-size: 150%;
		font-weight: bold;
		margin-left: 10px;
	}
	
	h2 {
		font-size: 130%;
		font-weight: bold;
		margin-left: 20px;
		color: #CCC;
	}
	
	h3 {
		margin-top: 30px;
		font-size: 110%;
		font-weight: bold;
		padding: 20px;
		border: 1px solid #777;
		border-bottom: none;
		margin-bottom: 0;
		color: #AAA;
		padding-top: 10px;
		padding-bottom: 10px;
	}
	
	a {
		text-decoration: none;
	}
	
	button {
		color: black;
		background-color: #BBB;
		border: 2px solid #777;
		height: 30px;
		cursor: pointer;
	}
	
	button:hover {
		background-color: #FFF;
	}
	
	button:active {
		color: #900;
	}
	
	li.directory a {
		color: #FF0;
	}
	
	li.directory a:visited {
		color: #AA0;
	}
	
	li.file a {
		color: #99F;
	}
	
	li.directory a:hover {
		text-decoration: underline;
		color: #FFF;
	}
	
	li.file a:hover {
		text-decoration: underline;
		color: #FFF;
	}
	
	li.file, li.directory {
		padding: 2px;
	}
	
	li.directory:hover {
		background-color: #044;
	}
	
	li.file:hover {
		background-color: #044;
	}
	
	#footer {
		margin-top: 30px;
		color: #999;
		font-size: 90%;
		margin-bottom: 30px;
		text-align: right;
	}
	
	#footer div {
		text-align: center;
	}
	
	#footer a img {
		border: none;
	}
	
	#footer img {
		margin-top: 20px;
	}
	
	li {
		list-style-type: none;
		padding: 1px;
	}
	
	span.name {
	
		padding-left: 10px;
	}
	
	span.size {
		float: right;
		text-align: right;
		padding-right: 10px;
		color: white;
	}
	
	span.line {
		display: inline;
		background-color: transparent;
		padding-left: 10px;
		padding-right: 10px;
		padding-top: 1px;
		padding-bottom: 1px;
	}
	
	#back {
		padding-left: 10px;
		padding-right: 10px;
		margin-bottom: 5px;
	}
	
	#back a, #root a {
		color: #F00;
	}
	
	#back a:hover, #root a:hover {
		color: #FFF;
	}
	
	#root {
		margin-bottom: 10px;
	}
	
	ul {
		margin: 0;
		padding: 0;
	}
	
	#list {
		padding: 12px;
		margin: 0;
		padding-bottom: 16px;
		border: 1px solid #777;
	}
	
	#path {
		color: #0C0;
	}
	
	#path a {
		color: #0C0;
	}
	
	#path a:hover {
		color: #FFF;
		text-decoration: underline;
	}
	
	li.empty {
		color: #FFF;
		padding-left: 10px;
		font-style: italic;
	}
	
	li.c0 {

	}
	
	li.c1 {

	}
	
	#error {
		font-weight: bold;
		font-size: 140%;
		margin-left: 10px;
		color: #F00;
	}
	
	#errorie7 {
		margin-left: 20px;
	}
	
	#errorie7 h2 {
		margin: 0;
		color: #F00;
		margin-bottom: 15px;
	}
	
	#errorie7 p {
		color: #FFF;
		margin: 0;
		margin-bottom: 3px;
	}
	
	#errorie7 ul {
		margin-top: 15px;
		margin-bottom: 15px;
	}
	
	#errorie7 li {
		list-style-type: disc;
		list-style-position: inside;
	}
	
	#errorie7 a {
		color: #FF0;
	}
	
	#errorie7 a:hover {
		color: #FFF;
		text-decoration: underline;
	}
	
	span.check {
		display: block;
		float: left;
		width: 12px;
		
	}
	
	span.check input {
		margin: 0;
		padding: 0;
		margin-bottom: 3px;
		vertical-align: middle;
	}
	
	fieldset {
		border: none;
		margin: 0;
		padding: 0;
	}
	
	#downloadall {
		margin-top: 20px;
		text-align: right;
	}
	
	#downloadall button {
		margin-right: 12px;
		margin-bottom: 3px;
	}
	
	</style>
WACAMOLE

my $NOMBRE = "Inti FileServer";
my $ACRON = "IFS";
my $VERSION = "v0.4"; 

my $BUFSIZ = 4096;

my %IPs = ();
my $sport = 0;

my $noipex = 1;

my $actual = '';
my $inicio = '';
my %dirs = ();

my %files = ();
my $numfiles = 0;
my $totalsize = 0;

$| = 1;

sub toHuman
{
	my $num = shift;
	my $unit = "bytes";
	
	if ($num > 1073741824) { $unit = "Gigabytes"; $num /= 1073741824; }
	elsif ($num > 1048576) { $unit = "Megabytes"; $num /= 1048576; }
	elsif ($num > 1024) { $unit = "Kilobytes"; $num /= 1024; }
	
	if ($unit ne "bytes")
	{ return sprintf('%.3f',$num)." $unit"; }
	else { return "$num $unit"; }
}

sub params
{
	my $na = @ARGV;

	unless ($na > 0 && $na < 4)
	{
		print "Please, specify one directory to share and an optional TCP port number.\nUso: ./ifs.pl <directory> [<port>]\n\n";
		exit 1;
	}
	
	if ($ARGV[0] eq '--help')
	{
		print "Use: ./ifs.pl <directory> [<port>]\n\n";
		exit 0;
	}
	
	$inicio = Cwd::realpath($ARGV[0]);
	unless (-d $inicio && -r $inicio)
	{
		print "Please, specify a valid path to share.\nUso: ./ifs.pl <directory> [<port>]\n\n";
		exit 1;
	}
	
	if (defined($ARGV[1]))
	{
		unless ($ARGV[1] =~ /^\d+$/ && $ARGV[1] > 1023 && $ARGV[1] < 65536)
		{
			print "Please, specify a valid port number (1024 - 65535).\nUso: ./ifs.pl <directory> [<port>]\n\n";
			exit 1;
		}
		else
		{
			$sport = $ARGV[1];
		}
	}
	
	# $noipex = 1 if (defined($ARGV[2]) && $ARGV[2] eq '--skip');
	
	$actual = Cwd::cwd();
	
	print "Getting lista de ficheros...";

	File::Find::find( sub {
		my $name = $File::Find::name;
		my $basename = $name; $basename =~ s/^$inicio//;

		if (-e $name && -r $name)
		{
			my $size = stat($name)->size;
			my $isDir = 1;
			unless (-d $name) { $isDir = 0; $numfiles++; $totalsize += $size; }
			
			$files{$basename} = { 'name' => $name, 'size' => $size, 'isdir' => $isDir };
		}
	}, $inicio);
	
	print "OK (", $numfiles, " files and $totalsize bytes)\n";
	
	return 1;
}

sub ips
{
	my $interface;
	
	foreach ( qx{ (LC_ALL=C /sbin/ifconfig -a 2>&1) } )
	{
		    $interface = $1 if /^(\S+?):?\s/;
		    next unless defined $interface;
		    $IPs{$interface}->{'STATE'}=uc($1) if /\b(up|down)\b/i;
		    $IPs{$interface}->{'IP'}=$1 if /inet\D+(\d+\.\d+\.\d+\.\d+)/i;
	}
	
	return 1;
}

sub extern
{
	my $request = HTTP::Request->new(GET => 'http://www.whatismyip.com/automation/n09230945.asp');
	my $ua = LWP::UserAgent->new;
	my $response = $ua->request($request);
	return 0 unless $response;
	
	my $pip = $response->content;
	
	return 0 unless ($pip =~ /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/);
	
	return $pip;
}

sub existeRuta
{
	my $path = shift;
	
	return 1 if ($path eq '/');
	return 1 if (defined($files{$path}));
	
	return 0;
}

sub esDirectorio
{
	my $path = shift;
	
	return 1 if ($path eq '/');
	return 0 unless (defined($files{$path}));
	return $files{$path}->{'isdir'};
	
	return 0;
}

sub listaDirectorio
{
	my $path = shift;
	
	$path = '' if ($path eq '/');
	
	my @k = keys %files;
	
	@k = grep /^$path\/[^\/]+$/, @k; # Posiblemente falle si el nombre del fichero *contiene* barras 
	
	my @dirs = (); my @fils = ();
	
	foreach my $key (@k)
	{
		if ($files{$key}->{'isdir'}) { push @dirs, $key }
		else { push @fils, $key }
	}
	
	my @rtn = ( sort(@dirs), sort(@fils) );
	
	return @rtn;
}

sub sendDirectorio
{
	my $cliente = shift;
	my $ruta = shift;
	
	my @dir = &listaDirectorio($ruta);
	my $human = &toHuman($totalsize);
	
	my $html = $HTMLTEMPLATE;
	$html .= <<WACAMOLE;
	<title>$ACRON - Files in $ruta</title>
</head>
<body>
	<h1>$NOMBRE ($ACRON) [ $VERSION ]</h1>
	<h2>Sharing $numfiles files ($human)</h2>
	<h3>Current path: <span id="path"><a href="$ruta">$ruta</a></span></h3>
	<div id="list">
WACAMOLE

	unless ($ruta eq '' || $ruta eq '/')
	{
		my $up = $ruta;	$up =~ s/\/[^\/]+$//;
		$up = '/' if ($up eq '');
	
		$html .= "<div id=\"root\"><a href=\"/\">Root ( / )</a></div>\n";
		$html .= "<div id=\"back\"><a href=\"$up\">Up ( .. )</a></div>\n"
	}
	
	my $rutaenco = encodeURL($ruta);
	
	$html .= "<form method=\"get\" action=\"\"><fieldset>\n";
	$html .= "<ul>\n";

	my $n = @dir;
	unless ($n)
	{
		$html .= "<li class=\"empty\">- EMPTY DIRECTORY -</li>\n" unless $n;
	}
	else
	{	
		my $cont = 0;
		foreach my $item (@dir)
		{
			$cont++; my $clase = $cont % 2?"c0":"c1";
			my $name = basename($item);
			my $link = $item; $link = encodeURL($link);
			my $baselink = $name; #$baselink = encodeURL($baselink);
			my $size = $files{$item}->{'size'};
			my $human = &toHuman($size);
			my $dire = $files{$item}->{'isdir'};
			if (!$dire) { $html .= "<li class=\"file $clase\"><span class=\"name\"><span class=\"check\"><input type=\"checkbox\" name=\"file\" value=\"$baselink\" /></span><a href=\"$link\">$name</a></span><span class=\"size\" onmouseover=\"this.innerHTML = '$human';\" onmouseout=\"this.innerHTML = '$size bytes';\">$size bytes</span></li>\n"; }
			else { $html .= "<li class=\"directory $clase\"><span class=\"name\"><span class=\"check\"><input type=\"checkbox\" name=\"file\" value=\"$baselink\" /></span><a href=\"$link\">$name</a></span><span class=\"size\">&lt;DIR&gt;</span></li>\n"; }
		}
	}

	$html .= <<WACAMOLE;
	</ul>
	<div id="downloadall"><button type="submit" name="downloadall" onclick="return confirm('Do you want to download all selected files?');" value="1">Download selected files</button><button type="button" onclick="if (confirm('Do you want to download current directory?')) document.location.href = '$rutaenco?download=1';">Download current directory</button></div>
	</fieldset></form>
	</div>
	<div id="footer">
		<div>~ &copy; 2013, Int_10h ~</div>
		<a href="https://github.com/inticardo/ifs"><img src="__favicon__.gif" alt="Inti FileServer" /></a>
	</div>
</body>
</html>

WACAMOLE

	&sendPage($cliente, $html);
}

sub sendNotFound
{
	my $cliente = shift;
	my $ruta = shift;
	
	my $html = $HTMLTEMPLATE;
	$html .= <<WACAMOLE;
	<title>$ACRON - (404) Path not found: $ruta</title>
</head>
<body>
	<h1>$NOMBRE ($ACRON) [ $VERSION ]</h1>
	<h2>Sharing $numfiles files ($totalsize bytes)</h2>
	<h3>Current path: <span id="path"><a href="$ruta">$ruta</a></span></h3>
	<div id="list">
		<div id="root"><a href="/">Root ( / )</a></div>
		<div id="error">(404) Path not found.</div>
	</div>
	<div id="footer">
		<div>~ &copy; 2013, Int_10h ~</div>
		<a href="https://github.com/inticardo/ifs"><img src="__favicon__.gif" alt="Inti FileServer" /></a>
	</div>
</body>
</html>
	
WACAMOLE
	my $head = new HTTP::Headers();
	$head->content_type('text/html');
	#$head->header('Content-Type' => 'text/html');
	
	$cliente->send_response( new HTTP::Response(404, 'NOT FOUND', $head, $html) );
}

sub sendVersionError
{
	my $cliente = shift;
	
	my $html = $HTMLTEMPLATE;
	$html .= <<WACAMOLE;
	<title>$ACRON - (403) Browser not supported</title>
</head>
<body>
	<h1>$NOMBRE ($ACRON) [ $VERSION ]</h1>
	<div id="errorie7">
		<h2>No, no, no. Browser not supported :P</h2>
		<p>But you can use:</p>
		<ul>
			<li><a href="http://www.mozilla.com/firefox">Mozilla Firefox</a></li>
			<li><a href="http://www.opera.com">Navegador Opera</a></li>
			<li><a href="http://www.google.com/chrome">Google Chrome</a></li>
		</ul>
		<p>Good luck!</p>
	</div>
	<div id="footer">
		<div>~ &copy; 2013, Int_10h ~</div>
		<a href="https://github.com/inticardo/ifs"><img src="__favicon__.gif" alt="Inti FileServer" /></a>
	</div>
</body>
</html>
	
WACAMOLE
	my $head = new HTTP::Headers();
	$head->content_type('text/html');
	#$head->header('Content-Type' => 'text/html');
	
	$cliente->send_response( new HTTP::Response(403, 'IE7 ERROR', $head, $html) );
}

sub getRealPath
{
	my $ruta = shift;
	
	$ruta = '' if ($ruta eq '/');
	
	unless ($ruta eq '')
	{
		$ruta = $files{$ruta}->{'name'};
	}
	else
	{
		$ruta = $inicio;
	}
	
	return $ruta;
}

sub downloadDir
{
	# Versión con procesos + hilo para esperar al zombie
	my $cliente = shift;
	my $ruta = shift;

	$ruta = &getRealPath($ruta);
	
	my $head = new HTTP::Headers();
	$head->content_type('application/force-download');
	$head->header('Content-Transfer-Encoding', 'binary');
	$head->header('Content-Disposition', 'attachment; filename=download.tar');

	my $tar = "cd \"$ruta\";tar cf - -C \"$ruta\" * |";	

	my $pid = fork();
	if ($pid == 0)
	{
		my $FILESEND;
		
		unless (open($FILESEND, $tar))
		{
			&sendNotFound($cliente, $ruta);
			exit 1;
		}
		
		binmode($FILESEND);
		
		my $res = new HTTP::Response(200, 'OK', $head, sub {
			my $buf = '';

			close($FILESEND) unless (read($FILESEND, $buf, $BUFSIZ));
	
			return $buf;
		});
		
		$cliente->send_response( $res );
	
		exit 0;
	}
	
	my $thread = threads->create( sub {
		threads->detach();
		
		waitpid $pid, 0;		
	}, $pid);
}

sub downloadAll
{
	# Versión con procesos + hilo para esperar al zombie
	my $cliente = shift;
	my $ruta = shift;
	my @ficheros = @_;

	$ruta = &getRealPath($ruta);
	
	my $head = new HTTP::Headers();
	$head->content_type('application/force-download');
	$head->header('Content-Transfer-Encoding', 'binary');
	$head->header('Content-Disposition', 'attachment; filename=download.tar');

	my $tar = "tar cf - -C $ruta ".join(" ", @ficheros)." |";	

	my $pid = fork();
	if ($pid == 0)
	{
		my $FILESEND;
		
		unless (open($FILESEND, $tar))
		{
			&sendNotFound($cliente, $ruta);
			exit 1;
		}
		
		binmode($FILESEND);
		
		my $res = new HTTP::Response(200, 'OK', $head, sub {
			my $buf = '';

			close($FILESEND) unless (read($FILESEND, $buf, $BUFSIZ));
	
			return $buf;
		});
		
		$cliente->send_response( $res );
	
		exit 0;
	}
	
	my $thread = threads->create( sub {
		threads->detach();
		
		waitpid $pid, 0;		
	}, $pid);
}

sub sendPage
{
	my $cliente = shift;
	my $text = shift;
	
	my $head = new HTTP::Headers();
	$head->content_type('text/html');
	#$head->header('Content-Type' => 'text/html');
	
	$cliente->send_response( new HTTP::Response(200, 'OK', $head, $text) );
}

sub downloadFile # Modificar igual que las otras 2 descargas
{
	# Versión con procesos + hilo para esperar al zombie
	my $cliente = shift;
	my $ruta = shift;
	
	my $fichero = $files{$ruta}->{'name'};
	my $tamanyo = $files{$ruta}->{'size'};

	#$ruta = &getRealPath($ruta);
	
	my $head = new HTTP::Headers();
	$head->content_type('application/force-download');
	$head->header('Content-Transfer-Encoding', 'binary');
	$head->content_length($tamanyo);
	#$head->header('Content-Disposition', 'attachment; filename=download.tar');

	my $pid = fork();
	if ($pid == 0)
	{
		my $FILESEND;
		
		unless (open($FILESEND, $fichero))
		{
			&sendNotFound($cliente, $ruta);
			exit 1;
		}
		
		binmode($FILESEND);
		
		my $res = new HTTP::Response(200, 'OK', $head, sub {
			my $buf = '';

			close($FILESEND) unless (read($FILESEND, $buf, $BUFSIZ));
	
			return $buf;
		});
		
		$cliente->send_response( $res );
	
		exit 0;
	}
	
	my $thread = threads->create( sub {
		threads->detach();
		
		waitpid $pid, 0;		
	}, $pid);
}

sub downloadFavicon
{
	# Versión con procesos + hilo para esperar al zombie
	my $cliente = shift;
	
	my $head = new HTTP::Headers();
	$head->content_type('image/gif');
	$head->header('Content-Transfer-Encoding', 'binary');
	$head->content_length($faviconsize);
	#$head->header('Content-Disposition', 'attachment; filename=download.tar');

	my $pid = fork();
	if ($pid == 0)
	{		
		my $res = new HTTP::Response(200, 'OK', $head, $favicon);

		$cliente->send_response( $res );
	
		exit 0;
	}
	
	my $thread = threads->create( sub {
		threads->detach();
		
		waitpid $pid, 0;		
	}, $pid);
}

sub decodeURL
{
	my $url = shift;
	
	$url =~ s/\+/ /g;
	$url =~ s/\%([A-Fa-f0-9]{2})/pack('C', hex($1))/seg;
	
	#return uri_unescape($url);
	
	return $url;
}

sub encodeURL
{
	my $url = shift;
	
	$url =~ s/([^A-Za-z0-9\/_\-\?\.])/sprintf("%%%02X", ord($1))/seg;
	
	#return uri_escape($url);
	
	return $url;
}

sub extraeFiles
{
	my $cadena = shift;
	#my $ruta = shift;
	
	#$ruta = &getRealPath($ruta);
	
	$cadena =~ /\?(.+&)downloadall=1$/;
	$cadena = $1;
	
	my @rtn = ();
	while ($cadena =~ /file=([^&]+)&/g )
	{
		my $f = &decodeURL($1);
		push @rtn, "\"$f\"";
	}
	
	return @rtn;
}

sub gestionaPeticion
{
	my $cliente = shift;
	my $request = shift;
	my $ua = $request->header('user-agent');
	
	my $navstr = &decodeURL($request->url->as_string);
	my $ruta = &decodeURL($request->url->path);
		
	$ruta =~ s/\/+$// if ($ruta ne '/');
	
	my $existeRuta = 0;
	my $tagDescarga = 0;
	my $tagDescargaFicheros = 0;
	my $esDescarga = 0;
	my $esDescargaDire = 0;
	my $esDescargaFiles = 0;
	
	$tagDescarga = 1 if ($request->url->as_string =~ /\?download=1$/ );
	$tagDescargaFicheros = 1 if ($request->url->as_string =~ /&downloadall=1$/ );
	$existeRuta = 1 if ($navstr !~ /\/\// && &existeRuta($ruta));
	$esDescarga = 1 if ($existeRuta && !&esDirectorio($ruta));
	$esDescargaDire = 1 if ($existeRuta && &esDirectorio($ruta) && $tagDescarga);
	$esDescargaFiles = 1 if ($existeRuta && &esDirectorio($ruta) && $tagDescargaFicheros);
	
	print "- [", $cliente->peerhost, ":", $cliente->peerport,"] Client query ( ", $navstr, " ) - ( path: ", $ruta, " ) "; #- ( ", ($existeRuta?($esDescarga?"DESCARGA":"LISTADO"):"RUTA INCORRECTA"), " ).\n";
	#print Dumper($request);
	
	if ($ua =~ /MSIE ([^;]+);/)
	{
		if ($1 < 8)
		{
			if ($ruta eq '/__favicon__.gif')
			{
				print "- ( FAVICON )\n";
				&downloadFavicon($cliente);
				return;
			}
			else
			{
				print "- ( <= IE 7 )\n";
				&sendVersionError($cliente);
				return;
			}
		}
	}
	
	if (!$existeRuta)
	{
		if ($ruta eq '/__favicon__.gif')
		{
			print "- ( FAVICON )\n";
			&downloadFavicon($cliente);
		}
		else
		{
			print "- ( NOT FOUND )\n";
			&sendNotFound($cliente, $ruta);
		}
		#$cliente->send_error(RC_FORBIDDEN);
	}
	else
	{
		unless ($esDescarga)
		{
			if ($tagDescarga)
			{	
				# Descargar directorio
				# IO::Pipe con fork , exec
				# Se lanzaría un hilo que a su vez haría una pipe y un fork, dentro del fork una redirect exec al tar
				# desde el otro lado del fork (aun siendo hilo) se lanzaria el sub de envio a cliente
				# leyendo desde el otro lado de la pipe de 4k en 4k
				print "- ( DIRECTORY DOWNLOAD )\n";
				&downloadDir($cliente, $ruta);
			}
			elsif ($tagDescargaFicheros)
			{
				my $cadena = $request->url->as_string;
				my @ficheros = &extraeFiles($cadena);
				print "- ( FILES DOWNLOAD: ".join(", ", @ficheros). " )\n";
				&downloadAll($cliente, $ruta, @ficheros);
				#$cliente->send_error(RC_FORBIDDEN);
			}
			else
			{
				# Listado
				print "- ( LIST )\n";
				&sendDirectorio($cliente, $ruta);
			}
		}
		else
		{
			# Descargar archivo individual
			print "- ( SINGLE DOWNLOAD )\n";
			&downloadFile($cliente, $ruta);
		}
	}
}

################ MAIN ###################

print "* $NOMBRE [ $VERSION ] *\n\n";

&params;

print "Discovering IPs... ";
my $result = &ips;
if ($result) { print "OK\n"; } else { print "FAIL!!!\n"; }

my $ex = 0;
unless ($noipex)
{
	print "Intentando averiguar IP externa... ";
	$ex = &extern;
	if ($ex) { print "OK\n"; } else { print "FAIL!!!\n"; }
}

print "Opening server... ";
my $d;
$d = new HTTP::Daemon ( 'LocalPort' => $sport, 'Reuse' => 1 ) if ($sport);
$d = new HTTP::Daemon ( 'Reuse' => 1 ) unless ($sport);

die "Server could not be opened: $!\n" unless $d;
print "OK\n\n";

print "Sharing '", $inicio, "' and all recursive directories.\n\n";

my $port = $d->sockport;
print "You can connect with:\n";
foreach my $key ( keys %IPs )
{
	print " - Interface $key : < http://", $IPs{$key}->{'IP'}, ":", $port, " >\n"
		if (defined($IPs{$key}->{'IP'}));
}
print " - Posible dirección externa: < http://", $ex, ":", $port, " >\n   (puede ser necesario que abra el puerto ".$port." TCP en su router para permitir conexiones externas)\n" if ($ex);

print "\n";

my $rs = new IO::Select();
$rs->add($d);
while (1)
{
	my ($rhs) = IO::Select->select($rs, undef, undef, 5);
	
	foreach my $rh (@$rhs)
	{
		if ($rh == $d) # Servidor , aceptamos
		{
			my $ns = $d->accept();
			$rs->add($ns);
			print "- [", $ns->peerhost, ":", $ns->peerport,"] Client connect.\n";
		}
		else
		{
			my $req = $rh->get_request();
			unless ($req)
			{
				$rs->remove($rh);
				print "- [", $rh->peerhost, ":", $rh->peerport,"] Client disconnect.\n";
				close($rh);
			}
			else
			{
				&gestionaPeticion($rh, $req);
			}
		}
	}
}

