unit setup_assp;
{$MODE DELPHI}
//{$mode objfpc}{$H+}
{$LONGSTRINGS ON}
//ln -s /usr/lib/libmilter/libsmutil.a /usr/local/lib/libsmutil.a
//apt-get install libmilter-dev
interface

uses
  Classes, SysUtils,strutils,RegExpr in 'RegExpr.pas',
  unix,IniFiles,setup_libs,distridetect,
  setup_suse_class,
  install_generic,
  setup_ubuntu_class;

  type
  tsetup_assp=class


private
     libs:tlibs;
     distri:tdistriDetect;
     install:tinstall;
     source_folder,cmd:string;




public
      constructor Create();
      procedure Free;
      procedure xinstall();
END;

implementation

constructor tsetup_assp.Create();
begin
libs:=tlibs.Create;
install:=tinstall.Create;
source_folder:='';
end;
//#########################################################################################
procedure tsetup_assp.Free();
begin
  libs.Free;
end;
//#########################################################################################
procedure tsetup_assp.xinstall();
var
   CODE_NAME:string;
   cmd:string;
begin

CODE_NAME:='APP_ASSP';
SetCurrentDir('/root');
    install.INSTALL_STATUS(CODE_NAME,20);
    install.INSTALL_PROGRESS(CODE_NAME,'{checking}');

    if not libs.PERL_GENERIC_INSTALL('File-Scan-ClamAV','File::Scan::ClamAV') then exit;
    if not libs.PERL_GENERIC_INSTALL('Net-IP-Match-Regexp','Net::IP::Match::Regexp') then exit;
    if not libs.PERL_GENERIC_INSTALL('Net-SenderBase','Net::SenderBase',false,true) then exit;
    if not libs.PERL_GENERIC_INSTALL('Tie-DBI','Tie::RDBM') then exit;


    if not libs.PERL_GENERIC_INSTALL('Compress-Raw-Zlib','Compress::Raw::Zlib') then exit;

    if libs.CHECK_PERL_MODULES('IO::Compress::Base')='2.008' then begin
          if not libs.PERL_GENERIC_INSTALL('IO-Compress-Base','IO::Compress::Base',true) then exit;
    end;

    if not libs.PERL_GENERIC_INSTALL('IO-Compress-Base','IO::Compress::Base') then exit;
    if not libs.PERL_GENERIC_INSTALL('IO-Compress-Zlib','Compress::Zlib') then exit;
    if not libs.PERL_GENERIC_INSTALL('Email-Valid','Email::Valid') then exit;
    if not libs.PERL_GENERIC_INSTALL('File-ReadBackwards','File::ReadBackwards') then exit;
    if not libs.PERL_GENERIC_INSTALL('Net-DNS-Resolver-Programmable','Net::DNS::Resolver::Programmable') then exit;
    if not libs.PERL_GENERIC_INSTALL('Error','Error') then exit;
    if not libs.PERL_GENERIC_INSTALL('NetAddr-IP','NetAddr::IP') then exit;



    libs.PERL_GENERIC_INSTALL('Mail-SPF','Mail::SPF');
    if not libs.PERL_GENERIC_INSTALL('Email-MIME-ContentType','Email::MIME::ContentType') then exit;
    if not libs.PERL_GENERIC_INSTALL('Email-MIME-Encodings','Email::MIME::Encodings') then exit;

    if not libs.PERL_GENERIC_INSTALL('Email-Address','Email::Address') then exit;
    if not libs.PERL_GENERIC_INSTALL('Email-MessageID','Email::MessageID') then exit;
    if not libs.PERL_GENERIC_INSTALL('Email-Simple','Email::Simple') then exit;



    if not libs.PERL_GENERIC_INSTALL('Email-MIME','Email::MIME') then exit;
    if not libs.PERL_GENERIC_INSTALL('Mail-SRS','Mail::SRS',false,true) then exit;


    if not libs.PERL_GENERIC_INSTALL('Return-Value','Return::Value') then exit;
    if not libs.PERL_GENERIC_INSTALL('Email-Send','Email::Send') then exit;




if DirectoryExists(ParamStr(2)) then source_folder:=ParamStr(2);
  install.INSTALL_STATUS(CODE_NAME,30);
  install.INSTALL_PROGRESS(CODE_NAME,'{downloading}');

  if length(source_folder)=0 then source_folder:=libs.COMPILE_GENERIC_APPS('assp');
  if not DirectoryExists(source_folder) then begin
     writeln('Install '+CODE_NAME+' failed...');
     install.INSTALL_STATUS(CODE_NAME,110);
     install.INSTALL_PROGRESS(CODE_NAME,'{failed}');
     exit;
  end;

  writeln('Working directory was "'+source_folder+'"');

  forceDirectories('/usr/share/assp/spam');
  forceDirectories('/usr/share/assp/notspam');
  forceDirectories('/usr/share/assp/errors');
  forceDirectories('/usr/share/assp/errors/spam');
  forceDirectories('/usr/share/assp/errors/notspam');
  fpsystem('/bin/cp -rf '+source_folder+'/* /usr/share/assp/');
  install.INSTALL_STATUS(CODE_NAME,100);
  install.INSTALL_PROGRESS(CODE_NAME,'{installed}');

  fpsystem('/bin/echo 1 >/etc/artica-postfix/settings/Daemons/EnableASSP');
  fpsystem('/etc/init.d/artica-postfix restart assp');

  end;
//#########################################################################################


end.
