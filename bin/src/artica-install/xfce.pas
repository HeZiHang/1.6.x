unit xfce;

{$MODE DELPHI}
{$LONGSTRINGS ON}

interface

uses
    Classes, SysUtils,variants,strutils,IniFiles, Process,logs,unix,RegExpr in 'RegExpr.pas',zsystem;

type LDAP=record
      admin:string;
      password:string;
      suffix:string;
      servername:string;
      Port:string;
  end;

  type
  txfce=class


private
     LOGS:Tlogs;
     SYS:TSystem;
     artica_path:string;
     inif:TiniFile;




public
    procedure   Free;
    constructor Create;
    procedure    INSTALL_XFCE();
    function     SPLASH_PATH():string;
    procedure    GDM();
    function     XFCE_DESKTOP_PID():string;
    function     XFCE_VERSION():string;
    function     XFCE_STATUS():string;
    procedure    XFCE_DEFAULT_SETTINGS();


END;

implementation

constructor txfce.Create;
begin
       forcedirectories('/etc/artica-postfix');
       LOGS:=tlogs.Create();
       SYS:=Tsystem.Create;


       if not DirectoryExists('/usr/share/artica-postfix') then begin
              artica_path:=ParamStr(0);
              artica_path:=ExtractFilePath(artica_path);
              artica_path:=AnsiReplaceText(artica_path,'/bin/','');

      end else begin
          artica_path:='/usr/share/artica-postfix';
      end;
end;
//##############################################################################
procedure txfce.free();
begin
    logs.Free;
    SYS.Free;
end;
//##############################################################################
procedure txfce.INSTALL_XFCE();
var
   l:TstringList;
   i:integer;
   RegExpr:TRegExpr;


begin
    if not FileExists('/usr/bin/xfce4-about') then begin
       logs.Debuglogs('INSTALL_XFCE:: xfce4 does not exists');
       exit;
    end;
       
       
    if not FileExists('/etc/artica-postfix/FROM_ISO') then begin
       logs.Debuglogs('INSTALL_XFCE:: This is not an installation from Artica ISO...');
       exit;
    end;
    
    GDM();
    
    
    if FileExists('/etc/xdg/autostart/xfce4-tips-autostart.desktop') then logs.DeleteFile('/etc/xdg/autostart/xfce4-tips-autostart.desktop');

          l:=TStringList.Create;

    if not FileExists('/usr/bin/auto_login') then begin
          l.Add('#! /bin/sh');
          l.Add('/bin/login -f root');
          logs.Debuglogs('INSTALL_XFCE:: Create /usr/bin/auto_login');
          l.SaveToFile('/usr/bin/auto_login');
          logs.OutputCmd('/bin/chmod 777 /usr/bin/auto_login');
    end;
    L.Clear;
    if not FileExists('/etc/inittab') then begin
       logs.Debuglogs('INSTALL_XFCE:: /etc/inittab does not exists');
       exit;
    end;
    l.LoadFromFile('/etc/inittab');
    RegExpr:=TRegExpr.Create;
    RegExpr.Expression:='^1:2345:respawn:/sbin/getty';


    for i:=0 to l.Count-1 do begin
        if RegExpr.Exec(l.Strings[i]) then begin
           l.Strings[i]:='1:2345:respawn:/sbin/getty -n -l /usr/bin/auto_login 38400 tty1';
           logs.Debuglogs('INSTALL_XFCE:: /etc/inittabmodify -n -l /usr/bin/auto_login 38400 tty1');
           l.SaveToFile('/etc/inittab');
           break;
        end;
    end;
    l.Clear;
l.add('# ~/.bashrc: executed by bash(1) for non-login shells.');
l.Add('');
l.Add('export PS1=''\h:\w\$ ''');
l.Add('umask 022');
l.Add('');
l.Add('# You may uncomment the following lines if you want `ls'' to be colorized:');
l.Add('export LS_OPTIONS=''--color=auto''');
l.Add('eval "`dircolors`"');
l.Add('alias ls=''ls $LS_OPTIONS''');
l.Add('alias ll=''ls $LS_OPTIONS -l''');
l.Add('alias l=''ls $LS_OPTIONS -lA''');
l.Add('if [ "$(tty)" = "/dev/tty1" -o "$(tty)" = "/dev/vc/1" ];');
l.Add('then startxfce4');
l.Add('fi');
l.SaveToFile('/root/.bashrc');
logs.Debuglogs('INSTALL_XFCE:: modify /root/.bashrc');

forcedirectories('/root/.config/autostart');
forcedirectories('/root/Desktop');
l.Clear;
l.add('[Desktop Entry]');
l.add('Encoding=UTF-8');
l.add('Version=0.9.4');
l.add('Type=Application');
l.add('Name=artica-postfix');
l.add('Comment=artica-application');
l.add('Exec=/usr/share/artica-postfix/bin/artica-interface');
l.add('StartupNotify=false');
l.add('Terminal=false');
l.add('Hidden=false');
l.add('Icon=applications-internet');
l.SaveToFile('/root/.config/autostart/artica.desktop');
l.SaveToFile('/root/Desktop/artica.desktop');


l.free;
if FileExists(artica_path+'/img/desktop-splash') then logs.OutputCmd('/bin/mv ' + artica_path+'/img/desktop-splash ' + SPLASH_PATH());

if FileExists('/usr/share/desktop-base/profiles/xdg-config/xfce4-session/xfce4-session.rc') then begin
   inif:=TiniFile.Create('/usr/share/desktop-base/profiles/xdg-config/xfce4-session/xfce4-session.rc');
   inif.WriteString('General','SaveOnExit','False');
   inif.Free;
end;
    XFCE_DEFAULT_SETTINGS();


end;
//##############################################################################
function txfce.SPLASH_PATH():string;
begin
if not FileExists('/usr/share/desktop-base/profiles/xdg-config/xfce4-session/xfce4-splash.rc') then exit('/usr/share/images/desktop-base/desktop-splash');
inif:=TIniFile.Create('/usr/share/images/desktop-base/desktop-splash');
result:=inif.ReadString('Engine: simple','Image','');
if length(result)=0 then exit('/usr/share/images/desktop-base/desktop-splash');
inif.free;
exit(result);
end;
//##############################################################################
procedure txfce.GDM();
var
   gdm:TiniFile;
begin
if not FileExists('/etc/gdm/gdm.conf') then exit;
sys.StripDiezes('/etc/gdm/gdm.conf');
gdm:=TiniFile.Create('/etc/gdm/gdm.conf');
if gdm.ReadString('security','AllowRoot','no')<>'true' then begin
   gdm.WriteString('security','AllowRoot','true');
   gdm.UpdateFile;
end;

gdm.free;
end;
//##############################################################################
function txfce.XFCE_VERSION():string;
var
   l:TstringList;
   i:integer;
   RegExpr:TRegExpr;
   filetemp:string;
begin
if not FileExists('/usr/bin/xfwm4') then exit;
  result:=SYS.GET_CACHE_VERSION('APP_XFCE');
   if length(result)>2 then exit;

   filetemp:=logs.FILE_TEMP();
   fpsystem('/usr/bin/xfwm4 --version >' + filetemp + ' 2>&1');
   
   if not FileExists(filetemp) then exit;

   l:=TstringList.Create;
   l.LoadFromFile(filetemp);
   logs.DeleteFile(filetemp);
   
   RegExpr:=TRegExpr.Create;
   RegExpr.Expression:='Xfce\s+([0-9\.]+)';
   for i:=0 to l.Count-1 do begin
       if RegExpr.Exec(l.Strings[i]) then begin
          result:=RegExpr.Match[1];
          break;
       end;
  end;
  
  RegExpr.free;
  l.free;
  SYS.SET_CACHE_VERSION('APP_XFCE',result);
end;




//##############################################################################
function txfce.XFCE_DESKTOP_PID():string;
var sys:Tsystem;
begin
   sys:=Tsystem.Create;
   result:=SYS.PIDOF('/usr/bin/xfdesktop');
end;
//##############################################################################
procedure txfce.XFCE_DEFAULT_SETTINGS();
begin
if not FileExists('/usr/bin/xfdesktop') then exit;

if not FileExists('/etc/artica-postfix/FROM_ISO') then begin
       logs.Debuglogs('XFCE_DEFAULT_SETTINGS:: This is not an installation from Artica ISO...');
       exit;
    end;
    
    if FileExists(artica_path + '/bin/install/xfce4-panel.tar.gz') then begin
       ForceDirectories('/root/.config/xfce4');
       fpsystem('tar -xf '+ artica_path + '/bin/install/xfce4-panel.tar.gz -C /root/.config/xfce4');
    end;
    
end;
//##############################################################################

function txfce.XFCE_STATUS():string;
var pidpath:string;
begin
if not FileExists('/usr/bin/xfdesktop') then exit;
pidpath:=logs.FILE_TEMP();
fpsystem(SYS.LOCATE_PHP5_BIN()+' /usr/share/artica-postfix/exec.status.php --xfce >'+pidpath +' 2>&1');
result:=logs.ReadFromFile(pidpath);
logs.DeleteFile(pidpath);
end;
//#########################################################################################




end.
