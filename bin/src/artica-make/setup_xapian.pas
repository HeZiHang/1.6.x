unit setup_xapian;
{$MODE DELPHI}
//{$mode objfpc}{$H+}
{$LONGSTRINGS ON}
//ln -s /usr/lib/libmilter/libsmutil.a /usr/local/lib/libsmutil.a
//apt-get install libmilter-dev
interface

uses
  Classes, SysUtils,strutils,RegExpr in 'RegExpr.pas',
  unix,IniFiles,setup_libs,distridetect,zsystem,
  install_generic;

  type
  install_xapian=class


private
     libs:tlibs;
     distri:tdistriDetect;
     install:tinstall;
   source_folder,cmd:string;
   webserver_port:string;
   artica_admin:string;
   artica_password:string;
   ldap_suffix:string;
   mysql_server:string;
   mysql_admin:string;
   mysql_password:string;
   ldap_server:string;
   SYS:Tsystem;




public
      constructor Create();
      procedure Free;
      procedure xinstall();
   function libinstall():boolean;
   function phpinstall():boolean;
   function unzip():boolean;
   function omegainstall():boolean;
   function antiword():boolean;
   function unrtf():boolean;
   function catdoc():boolean;
   function xpdf():boolean;

END;

implementation

constructor install_xapian.Create();
begin
libs:=tlibs.Create;
install:=tinstall.Create;
source_folder:='';
SYS:=Tsystem.Create();
if DirectoryExists(ParamStr(2)) then source_folder:=ParamStr(2);
end;
//#########################################################################################
procedure install_xapian.Free();
begin
  libs.Free;

end;

//#########################################################################################
procedure install_xapian.xinstall();
var
   CODE_NAME:string;
   cmd:string;
begin

  CODE_NAME:='APP_XAPIAN_TOOLS';
  SetCurrentDir('/root');

  install.INSTALL_STATUS(CODE_NAME,10);
  writeln('Installing antiword');
  antiword();
  install.INSTALL_STATUS(CODE_NAME,20);
  writeln('Installing unrtf');
  install.INSTALL_STATUS(CODE_NAME,30);
  unrtf();
  writeln('Installing catdoc');
  install.INSTALL_STATUS(CODE_NAME,40);
  catdoc();
  writeln('Installing xpdf');
  install.INSTALL_STATUS(CODE_NAME,50);
  xpdf();
  writeln('Installing unzip');
  install.INSTALL_STATUS(CODE_NAME,100);
  unzip();


end;
//#########################################################################################
function install_xapian.libinstall():boolean;
var
   CODE_NAME:string;
   cmd:string;
begin
  result:=false;
  CODE_NAME:='APP_XAPIAN';
  SetCurrentDir('/root');
  install.INSTALL_STATUS(CODE_NAME,10);
  install.INSTALL_STATUS(CODE_NAME,30);
  install.INSTALL_PROGRESS(CODE_NAME,'{downloading}');

  if length(source_folder)=0 then source_folder:=libs.COMPILE_GENERIC_APPS('xapian-core');



  if not DirectoryExists(source_folder) then begin
     writeln('Install '+CODE_NAME+' failed...');
     install.INSTALL_STATUS(CODE_NAME,110);
     exit;
  end;

  writeln('Install '+CODE_NAME+' extracted on "'+source_folder+'"');
  install.INSTALL_STATUS(CODE_NAME,35);
  install.INSTALL_PROGRESS(CODE_NAME,'{compiling}');

  SetCurrentDir(source_folder);



cmd:='./configure';
cmd:=cmd+' CFLAGS=-O2 CXXFLAGS=-O2 --prefix=/usr --sysconfdir=/etc --disable-dependency-tracking';
writeln(cmd);
fpsystem(cmd);

install.INSTALL_PROGRESS(CODE_NAME,'{installing}');
install.INSTALL_STATUS(CODE_NAME,40);
fpsystem('make && make install');
fpsystem('/bin/rm -f /etc/artica-postfix/versions.cache');
SetCurrentDir('/root');

  if FileExists('/usr/bin/xapian-config') then begin
     install.INSTALL_PROGRESS(CODE_NAME,'{installed}');
     install.INSTALL_STATUS(CODE_NAME,100);
     result:=true;
     exit(true);
  end else begin
      writeln('Unable to stat /usr/bin/xapian-config');
      writeln('Install '+CODE_NAME+' library failed...');
        install.INSTALL_PROGRESS(CODE_NAME,'{failed}');
      install.INSTALL_STATUS(CODE_NAME,110);
      exit;
  end;





end;
//#########################################################################################
function install_xapian.omegainstall():boolean;
var
   CODE_NAME:string;
   cmd:string;
   xapian_config:string;
begin
  result:=false;
  CODE_NAME:='APP_XAPIAN_OMEGA';

  if FileExists('/usr/bin/omindex') then begin
     writeln('/usr/bin/omindex OK, Already installed.....');
     writeln('Aborting...');
     install.INSTALL_PROGRESS(CODE_NAME,'{installed}');
     install.INSTALL_STATUS(CODE_NAME,100);
     exit(true);
  end;
   xapian_config:=SYS.LOCATE_GENERIC_BIN('xapian-config');
  if not FileExists(xapian_config) then begin
     writeln('xapian-config !!! No such binary....');
     install.INSTALL_PROGRESS(CODE_NAME,'{failed}');
     install.INSTALL_STATUS(CODE_NAME,110);
     result:=false;
     exit(false);
  end;

  SetCurrentDir('/root');
  install.INSTALL_STATUS(CODE_NAME,50);
  install.INSTALL_STATUS(CODE_NAME,55);
  install.INSTALL_PROGRESS(CODE_NAME,'{downloading}');

  if length(source_folder)=0 then source_folder:=libs.COMPILE_GENERIC_APPS('xapian-omega');



  if not DirectoryExists(source_folder) then begin
     writeln('Install '+CODE_NAME+' (xapian-omega) failed...');
     install.INSTALL_STATUS(CODE_NAME,110);
     exit;
  end;

  writeln('Install '+CODE_NAME+' extracted on "'+source_folder+'"');
  install.INSTALL_STATUS(CODE_NAME,60);
  install.INSTALL_PROGRESS(CODE_NAME,'{compiling} xapian-omega');

  SetCurrentDir(source_folder);



cmd:='./configure CFLAGS=-O2 CXXFLAGS=-O2 --prefix=/usr --sysconfdir=/etc --mandir=/usr/share/man --disable-dependency-tracking';
writeln(cmd);
fpsystem(cmd);

install.INSTALL_PROGRESS(CODE_NAME,'{installing}');
install.INSTALL_STATUS(CODE_NAME,65);
fpsystem('make && make install');
fpsystem('/bin/rm -f /etc/artica-postfix/versions.cache');
SetCurrentDir('/root');

  if FileExists('/usr/bin/omindex') then begin
     install.INSTALL_PROGRESS(CODE_NAME,'{installed}');
     install.INSTALL_STATUS(CODE_NAME,100);
     exit(true);
  end;


writeln('Install '+CODE_NAME+' xapian-omega failed could not stat /usr/bin/omindex...');
install.INSTALL_STATUS(CODE_NAME,110);
install.INSTALL_PROGRESS(CODE_NAME,'{failed}');
exit;

end;
//#########################################################################################
function install_xapian.phpinstall():boolean;
var
   CODE_NAME:string;
   cmd:string;
   php_config:string;
   targetLibPath:string;
begin
  result:=false;
  CODE_NAME:='APP_XAPIAN_PHP';


  if not FileExists('/usr/bin/xapian-config') then begin
     install.INSTALL_PROGRESS(CODE_NAME,'{failed}');
     install.INSTALL_STATUS(CODE_NAME,110);
     result:=false;
     exit(false);
  end;

   targetLibPath:=SYS.LOCATE_PHP5_EXTENSION_DIR() + '/xapian.so';


  if FileExists(targetLibPath) then begin
     install.INSTALL_PROGRESS(CODE_NAME,'{installed}');
     install.INSTALL_STATUS(CODE_NAME,100);
     exit(true);
  end;


  php_config:=SYS.LOCATE_PHP5_CONFIG_BIN();

  if not FileExists(php_config) then begin
     writeln('Unable to stat php-config !');
     writeln('Install '+CODE_NAME+' failed...');
     install.INSTALL_STATUS(CODE_NAME,110);
     exit;
  end;





  SetCurrentDir('/root');
  install.INSTALL_STATUS(CODE_NAME,50);
  install.INSTALL_STATUS(CODE_NAME,55);
  install.INSTALL_PROGRESS(CODE_NAME,'{downloading}');

  if length(source_folder)=0 then source_folder:=libs.COMPILE_GENERIC_APPS('xapian-bindings');



  if not DirectoryExists(source_folder) then begin
     writeln('Install '+CODE_NAME+ 'xapian-php  failed...');
     install.INSTALL_PROGRESS(CODE_NAME,'{failed}');
     install.INSTALL_STATUS(CODE_NAME,110);
     exit;
  end;

  writeln('Install '+CODE_NAME+' extracted on "'+source_folder+'"');
  install.INSTALL_STATUS(CODE_NAME,60);
  install.INSTALL_PROGRESS(CODE_NAME,'{compiling}');

  SetCurrentDir(source_folder);



cmd:='./configure CFLAGS=-O2 CXXFLAGS=-O2 --prefix=/usr --sysconfdir=/etc --disable-dependency-tracking --with-php PHP_CONFIG='+php_config;
writeln(cmd);
fpsystem(cmd);

install.INSTALL_PROGRESS(CODE_NAME,'{installing}');
install.INSTALL_STATUS(CODE_NAME,65);
fpsystem('make && make install');
fpsystem('/bin/rm -f /etc/artica-postfix/versions.cache');
SetCurrentDir('/root');

  if FileExists(targetLibPath) then begin
     install.INSTALL_PROGRESS(CODE_NAME,'{installed}');
     install.INSTALL_STATUS(CODE_NAME,100);
     exit(true);
  end;


writeln('Install '+CODE_NAME+' failed... (unable to stat ' + targetLibPath+') with php-config='+php_config);
install.INSTALL_PROGRESS(CODE_NAME,'{failed}');
install.INSTALL_STATUS(CODE_NAME,110);
exit;

end;
//#########################################################################################
function install_xapian.antiword():boolean;
var
   CODE_NAME:string;
   cmd:string;
begin
  result:=false;
  CODE_NAME:='APP_ANTIWORD';

  if FileExists('/usr/bin/antiword') then begin
     install.INSTALL_STATUS(CODE_NAME,100);
     install.INSTALL_PROGRESS(CODE_NAME,'{installed}');
     exit(true);
  end;

  SetCurrentDir('/root');
  install.INSTALL_STATUS(CODE_NAME,73);
  install.INSTALL_STATUS(CODE_NAME,74);
  install.INSTALL_PROGRESS(CODE_NAME,'{downloading}');

  if length(source_folder)=0 then source_folder:=libs.COMPILE_GENERIC_APPS('antiword');



  if not DirectoryExists(source_folder) then begin
     writeln('Install antiword failed...');

     exit;
  end;

  writeln('Install antiword extracted on "'+source_folder+'"');
  install.INSTALL_STATUS(CODE_NAME,75);
  install.INSTALL_PROGRESS(CODE_NAME,'{compiling}');

SetCurrentDir(source_folder);
cmd:='/usr/bin/make -f Makefile.Linux';
writeln(cmd);
fpsystem(cmd);

install.INSTALL_PROGRESS(CODE_NAME,'{installing}');
install.INSTALL_STATUS(CODE_NAME,76);
fpsystem('/bin/rm -f /etc/artica-postfix/versions.cache');
SetCurrentDir('/root');

  if not FileExists(source_folder+'/antiword') then begin
     install.INSTALL_PROGRESS(CODE_NAME,'{failed}');
     install.INSTALL_STATUS(CODE_NAME,110);
     exit(false);
  end;

fpsystem('/bin/cp ' + source_folder+'/antiword /usr/bin/antiword');
fpsystem('/bin/cp ' + source_folder+'/kantiword /usr/bin/kantiword');
writeln('Install '+CODE_NAME+' success...');
install.INSTALL_STATUS(CODE_NAME,100);
install.INSTALL_PROGRESS(CODE_NAME,'{installed}');

exit;

end;
//########################################################################################
//http://www.gnu.org/software/unrtf/unrtf.html (/usr/bin/unrtf)
function install_xapian.unrtf():boolean;
var
   CODE_NAME:string;
   cmd:string;
begin
  result:=false;
  CODE_NAME:='APP_UNRTF';

  if FileExists('/usr/bin/unrtf') then begin
     install.INSTALL_STATUS(CODE_NAME,100);
     install.INSTALL_PROGRESS(CODE_NAME,'{installed}');
     exit(true);
  end;

  SetCurrentDir('/root');
  install.INSTALL_STATUS(CODE_NAME,73);
  install.INSTALL_STATUS(CODE_NAME,74);
  install.INSTALL_PROGRESS(CODE_NAME,'{downloading}');

  if length(source_folder)=0 then source_folder:=libs.COMPILE_GENERIC_APPS('unrtf');



  if not DirectoryExists(source_folder) then begin
     writeln('Install unrtf failed...');
     exit;
  end;
  SetCurrentDir(source_folder);
cmd:='./configure CFLAGS=-O2 CXXFLAGS=-O2 --prefix=/usr --sysconfdir=/etc --mandir=/usr/share/man';
writeln(cmd);
fpsystem(cmd);

install.INSTALL_PROGRESS(CODE_NAME,'{installing}');
install.INSTALL_STATUS(CODE_NAME,90);
fpsystem('make && make install');
fpsystem('/bin/rm -f /etc/artica-postfix/versions.cache');
SetCurrentDir('/root');

  if FileExists('/usr/bin/unrtf') then begin
     install.INSTALL_PROGRESS(CODE_NAME,'{installed}');
     install.INSTALL_STATUS(CODE_NAME,100);
     exit(true);
  end;


     install.INSTALL_STATUS(CODE_NAME,110);
     install.INSTALL_PROGRESS(CODE_NAME,'{failed}');
end;
//########################################################################################
//http://www.wagner.pp.ru/~vitus/software/catdoc/ (/usr/bin/unrtf)
function install_xapian.catdoc():boolean;
var
   CODE_NAME:string;
   cmd:string;
begin
  result:=false;
  CODE_NAME:='APP_CATDOC';

  if FileExists('/usr/bin/catdoc') then begin
     install.INSTALL_STATUS(CODE_NAME,100);
     install.INSTALL_PROGRESS(CODE_NAME,'{installed}');
     exit(true);
  end;

  SetCurrentDir('/root');
  install.INSTALL_STATUS(CODE_NAME,73);
  install.INSTALL_STATUS(CODE_NAME,74);
  install.INSTALL_PROGRESS(CODE_NAME,'{downloading}');

  if length(source_folder)=0 then source_folder:=libs.COMPILE_GENERIC_APPS('catdoc');



  if not DirectoryExists(source_folder) then begin
     writeln('Install unrtf failed...');
     exit;
  end;
SetCurrentDir(source_folder);
cmd:='./configure --prefix=/usr --sysconfdir=/etc --mandir=/usr/share/man';
writeln(cmd);
fpsystem(cmd);

install.INSTALL_PROGRESS(CODE_NAME,'{installing}');
install.INSTALL_STATUS(CODE_NAME,90);
fpsystem('make && make install');
fpsystem('/bin/rm -f /etc/artica-postfix/versions.cache');
SetCurrentDir('/root');

  if FileExists('/usr/bin/catdoc') then begin
     install.INSTALL_PROGRESS(CODE_NAME,'{installed}');
     install.INSTALL_STATUS(CODE_NAME,100);
     exit(true);
  end;

     install.INSTALL_STATUS(CODE_NAME,110);
     install.INSTALL_PROGRESS(CODE_NAME,'{failed}');

end;
//########################################################################################
//http://www.foolabs.com/xpdf/       ///usr/include/freetype2
function install_xapian.xpdf():boolean;
var
   CODE_NAME:string;
   cmd:string;
   LD_LIBRARY_PATH:string;
   CPPFLAGS:string;
   freetype2:string;
begin
  result:=false;
  CODE_NAME:='APP_XPDF';

LD_LIBRARY_PATH:='LD_LIBRARY_PATH="/opt/artica/lib:/opt/artica/db/lib:/opt/artica/mysql/lib/mysql" ';
       CPPFLAGS:=' CPPFLAGS="-I/opt/artica/include/ -I/opt/artica/include/libart-2.0/ -I/opt/artica/include/libpng12 ';
       CPPFLAGS:=CPPFLAGS + '-I/opt/artica/include/freetype2/ ';
       CPPFLAGS:=CPPFLAGS + '-I/opt/artica/include/ncurses/ ';
       CPPFLAGS:=CPPFLAGS + '-I/opt/artica/include/dbi/ ';
       CPPFLAGS:=CPPFLAGS + '-I/opt/artica/mysql/include/mysql ';
       CPPFLAGS:=CPPFLAGS + '-I/opt/artica/include/libxml2 ';
       CPPFLAGS:=CPPFLAGS + '-I/opt/artica/db/include ';
       CPPFLAGS:=CPPFLAGS + '-I/opt/artica/include/sasl ';
       CPPFLAGS:=CPPFLAGS + '-I/opt/artica/include/openssl" ';
       CPPFLAGS:=CPPFLAGS + 'LDFLAGS="-L/opt/artica/lib -L/opt/artica/db/lib -L/opt/artica/mysql/lib/mysql" ';
       CPPFLAGS:=CPPFLAGS + 'LDFLAGS="-L/opt/artica/lib -L/opt/artica/db/lib -L/opt/artica/mysql/lib/mysql"';


CPPFLAGS:='CPPFLAGS="-I/usr/include/freetype2';

  if FileExists('/usr/bin/pdfinfo') then begin
     install.INSTALL_STATUS(CODE_NAME,100);
     install.INSTALL_PROGRESS(CODE_NAME,'{installed}');
     exit(true);
  end;

  SetCurrentDir('/root');
  install.INSTALL_STATUS(CODE_NAME,73);
  install.INSTALL_STATUS(CODE_NAME,74);
  install.INSTALL_PROGRESS(CODE_NAME,'{downloading} xpdf');

  if length(source_folder)=0 then source_folder:=libs.COMPILE_GENERIC_APPS('xpdf');



  if not DirectoryExists(source_folder) then begin
     writeln('Install unrtf failed...');
     exit;
  end;

if FileExists('/usr/include/ft2build.h') then  freetype2:='/usr/include';
if FileExists('/usr/include/freetype2/freetype/ft2build.h') then  freetype2:='/usr/include/freetype2';

  SetCurrentDir(source_folder);
cmd:='./configure --prefix=/usr --sysconfdir=/etc/xpdf --mandir=/usr/share/man --without-x --enable-freetype2 --enable-opi --enable-wordlist --enable-multithreaded --with-freetype2-includes=/usr/include/freetype2';
writeln(cmd);
fpsystem(cmd);

install.INSTALL_PROGRESS(CODE_NAME,'{installing} xpdf');
install.INSTALL_STATUS(CODE_NAME,65);
fpsystem('make && make install');
fpsystem('/bin/rm -f /etc/artica-postfix/versions.cache');
SetCurrentDir('/root');

  if FileExists('/usr/bin/pdfinfo') then begin
     install.INSTALL_PROGRESS(CODE_NAME,'{installed}');
     install.INSTALL_STATUS(CODE_NAME,100);
     exit(true);
  end;

     install.INSTALL_STATUS(CODE_NAME,110);
     install.INSTALL_PROGRESS(CODE_NAME,'{failed}');
end;

//########################################################################################
function install_xapian.unzip():boolean;
var
   CODE_NAME:string;
   cmd:string;
   ziplocalversion:Single;
   zipremoteversion:Single;
begin
  result:=false;
  CODE_NAME:='APP_UNZIP';
  if ParamStr(2)<>'--force' then begin
  if FileExists('/usr/bin/unzip') then begin
     if not TryStrToFloat(SYS.APP_UNZIP_VERSION(),ziplocalversion) then ziplocalversion:=0;
     if not TryStrToFloat(libs.COMPILE_VERSION_STRING('unzip'),zipremoteversion) then zipremoteversion:=0;
     writeln('local:',ziplocalversion,' remote:',zipremoteversion);

     if ziplocalversion> zipremoteversion then begin
        install.INSTALL_STATUS(CODE_NAME,100);
        install.INSTALL_PROGRESS(CODE_NAME,'{installed}');
        exit(true);
     end;
  end;
  end;
  SetCurrentDir('/root');
  install.INSTALL_STATUS(CODE_NAME,73);
  install.INSTALL_STATUS(CODE_NAME,74);
  install.INSTALL_PROGRESS(CODE_NAME,'{downloading}');

  if length(source_folder)=0 then source_folder:=libs.COMPILE_GENERIC_APPS('unzip');



  if not DirectoryExists(source_folder) then begin
     writeln('Install unzip failed...');
     exit;
  end;
SetCurrentDir(source_folder);
cmd:='/usr/bin/make -f unix/Makefile LF2="" D_USE_BZ2=-DUSE_BZIP2 L_BZ2=-lbz2';
cmd:=cmd+' CC="gcc" CF="-g -Wall -O2 -I. -DACORN_FTYPE_NFS -DWILD_STOP_AT_DIR -DLARGE_FILE_SUPPORT';
cmd:=cmd+' -DUNICODE_SUPPORT -DUNICODE_WCHAR -DUTF8_MAYBE_NATIVE -DNO_LCHMOD -DDATE_FORMAT=DF_YMD -DUSE_BZIP2" unzips';
writeln(cmd);
fpsystem(cmd);

install.INSTALL_PROGRESS(CODE_NAME,'{installing}');
install.INSTALL_STATUS(CODE_NAME,65);


if FileExists(source_folder+'/funzip') then fpsystem('/bin/cp '+source_folder+'/funzip /usr/bin/funzip');
if FileExists(source_folder+'/unzip') then fpsystem('/bin/cp '+source_folder+'/funzip /usr/bin/unzip');
if FileExists(source_folder+'/unzipsfx') then fpsystem('/bin/cp '+source_folder+'/funzip /usr/bin/unzipsfx');


fpsystem('/bin/rm -f /etc/artica-postfix/versions.cache');
SetCurrentDir('/root');

  if FileExists('/usr/bin/unzip') then begin
     writeln('Success with version:' +SYS.APP_UNZIP_VERSION());
     install.INSTALL_PROGRESS(CODE_NAME,'{installed}');
     install.INSTALL_STATUS(CODE_NAME,100);
     exit(true);
  end;


     install.INSTALL_STATUS(CODE_NAME,110);
     install.INSTALL_PROGRESS(CODE_NAME,'{failed}');


end;
//########################################################################################



end.
