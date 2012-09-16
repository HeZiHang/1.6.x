unit setup_kas3;
{$MODE DELPHI}
//{$mode objfpc}{$H+}
{$LONGSTRINGS ON}

interface

uses
  Classes, SysUtils,strutils,RegExpr in 'RegExpr.pas',unix,IniFiles,setup_libs,distridetect,setup_suse_class,install_generic;

  type
  tsetup_kas3=class


private
     libs:tlibs;
     distri:tdistriDetect;
     install:tinstall;
public
      constructor Create();
      procedure Free;
      procedure install_kas3();
END;

implementation

constructor tsetup_kas3.Create();
begin
distri:=tdistriDetect.Create();
libs:=tlibs.Create;
install:=tinstall.Create;
end;
//#########################################################################################
procedure tsetup_kas3.Free();
begin
  libs.Free;
end;
//#########################################################################################
procedure tsetup_kas3.install_kas3();
var source_folder,cmd:string;

begin



install.INSTALL_STATUS('APP_KAS3',10);
install.INSTALL_PROGRESS('APP_KAS3','{downloading}');

  if FIleExists('/home/artica/packages/kas-3-3.0.284-1.tar.gz') then begin
     ForceDirectories('/tmp/artica-kas3');
     fpsystem('/bin/tar -xf /home/artica/packages/kas-3-3.0.284-1.tar.gz -C /tmp/artica-kas3/');
     source_folder:='/tmp/artica-kas3/usr';
  end else begin
      source_folder:=libs.COMPILE_GENERIC_APPS('kas');
  end;

if length(trim(source_folder))=0 then begin
     writeln('Install kas3 failed...');
     install.INSTALL_STATUS('APP_KAS3',110);
     exit;
end;
  if DirectoryExists(source_folder) then fpsystem('/bin/chown -R root:root '+source_folder);
  sleep(100);



{  if not DirectoryExists(source_folder+'/usr/local/ap-mailfilter3/bin') then begin
     writeln('Install kas3 failed...unable to stat "'+source_folder+'/local/ap-mailfilter3/bin"');
     install.INSTALL_STATUS('APP_KAS3',110);
     exit;
  end;}
  

     fpsystem('/usr/sbin/groupadd mailflt3');
     fpsystem('/usr/sbin/useradd -c "Kaspersky Anti-Spam user" -g mailflt3 -d /usr/local/ap-mailfilter3/run -s /bin/false mailflt3');

    install.INSTALL_PROGRESS('APP_KAS3','{installing}');
install.INSTALL_STATUS('APP_KAS3',20);
writeln('Installing kas3...');
fpsystem('/bin/cp -rf '+source_folder+'/* /usr/');

  if not DirectoryExists('/usr/local/ap-mailfilter3') then begin
         install.INSTALL_STATUS('APP_KAS3',110);
         writeln('Unable to install the software... Aborting...');
             install.INSTALL_PROGRESS('APP_KAS3','{failed}');
         exit;
    end;
 fpsystem('/bin/chown -R mailflt3:mailflt3 /usr/local/ap-mailfilter3/cfdata');
 fpsystem('/bin/chown -R mailflt3:mailflt3 /usr/local/ap-mailfilter3/conf');
 fpsystem('/bin/chown -R mailflt3:mailflt3 /usr/local/ap-mailfilter3/etc');
 fpsystem('/bin/chown -R mailflt3:mailflt3 /usr/local/ap-mailfilter3/log');
 fpsystem('/bin/chown -R mailflt3:mailflt3 /usr/local/ap-mailfilter3/run');
    

    install.INSTALL_STATUS('APP_KAS3',50);
    fpsystem('/usr/local/ap-mailfilter3/bin/scripts/post-upgrade');
    fpsystem('/usr/local/ap-mailfilter3/bin/scripts/post-install');
    writeln('Installing license key');
    fpsystem('/usr/local/ap-mailfilter3/bin/install-key /usr/share/artica-postfix/bin/install/KAS.key');
    fpsystem('/usr/local/ap-mailfilter3/bin/enable-updates.sh');
    install.INSTALL_STATUS('APP_KAS3',90);
    if not FileExists('/usr/local/ap-mailfilter3/etc/filter.conf') then fpsystem('/bin/cp /usr/share/artica-postfix/bin/install/filter.conf /usr/local/ap-mailfilter3/etc/filter.conf');
    if not FileExists('/usr/local/ap-mailfilter3/etc/keepup2date.conf') then fpsystem('/bin/cp /usr/share/artica-postfix/bin/install/kas.keepup2date.conf /usr/local/ap-mailfilter3/etc/keepup2date.conf');
    install.INSTALL_STATUS('APP_KAS3',100);
    writeln('success');
   install.INSTALL_PROGRESS('APP_KAS3','{installed}');
   if FIleExists('/home/artica/packages/kas-3-3.0.284-1.tar.gz') then fpsystem('/bin rm -f /home/artica/packages/kas-3-3.0.284-1.tar.gz');
   if DirectoryExists('/tmp/artica-kas3') then fpsystem('/bin/rm -rf /tmp/artica-kas3');

end;
//#########################################################################################
end.
