unit apt_class;

{$MODE DELPHI}
{$LONGSTRINGS ON}

interface

uses
    Classes,SysUtils,variants,strutils,IniFiles, Process,logs,unix,RegExpr in 'RegExpr.pas',zsystem;

  type
  tapt=class


private
     LOGS:Tlogs;
     SYS:TSystem;
     artica_path:string;
     function CheckTable():boolean;




public
    procedure   Free;
    constructor Create;
    procedure INSERT_DEB_PACKAGES();
    function CheckTableEmpty():boolean;
    function PACKAGE_EXTRA_INFO(package_name:string):string;
    procedure UNSTALL_MARK();
    procedure FIND(pattern:string);
    procedure INFO(pattern:string);
    procedure INSTALL_MARK();
    procedure Check();
    procedure upgrade();




END;

implementation

constructor tapt.Create;
begin
       forcedirectories('/etc/artica-postfix');
       forcedirectories('/opt/artica/tmp');
       LOGS:=tlogs.Create();
       SYS:=Tsystem.Create;

     if length(SYS.GET_INFO('EnableMysqlFeatures'))=0 then begin
       logs.Syslogs('stopping watchdog, artica-postfix.conf is currently in use...');
     end;

       if not DirectoryExists('/usr/share/artica-postfix') then begin
              artica_path:=ParamStr(0);
              artica_path:=ExtractFilePath(artica_path);
              artica_path:=AnsiReplaceText(artica_path,'/bin/','');

      end else begin
          artica_path:='/usr/share/artica-postfix';
      end;
end;
//##############################################################################
procedure tapt.free();
begin
    logs.Free;
    SYS.Free;


end;
//##############################################################################
function tapt.CheckTableEmpty():boolean;
begin
if logs.TABLE_ROWNUM('debian_packages','artica_backup')>0 then exit(true);
exit(false);
end;
//##############################################################################
function tapt.CheckTable():boolean;
   var
      sql:string;
begin
result:=false;
if SYS.GET_INFO('EnableMysqlFeatures')='0' then exit;
sql:='';
  if not LOGS.IF_TABLE_EXISTS('debian_packages','artica_backup') then begin
       sql:=sql+'CREATE TABLE `artica_backup`.`debian_packages` (';
       sql:=sql+'`package_name` VARCHAR( 255 ) NOT NULL ,';
       sql:=sql+'`package_version` VARCHAR( 255 ) NOT NULL ,';
       sql:=sql+'`package_status` varchar(10) NOT NULL,';
       sql:=sql+'`package_info` VARCHAR( 255 ) NOT NULL ,';
       sql:=sql+'`package_description` TEXT NOT NULL ,';
       sql:=sql+'UNIQUE KEY `package_name` (`package_name`),';
       sql:=sql+'KEY `package_version` (`package_version`),';
       sql:=sql+'KEY `package_status` (`package_status`)';
       sql:=sql+')';
       sql:=sql+')';
       if not logs.QUERY_SQL(Pchar(sql),'artica_backup') then begin
          logs.Syslogs('tapt.CheckTable() unable to create table debian_packages');
          exit;
       end;
  end;
  
sql:='';
  if not LOGS.IF_TABLE_EXISTS('debian_packages','artica_backup') then begin
       sql:=sql+'CREATE TABLE IF NOT EXISTS `debian_packages_logs` (';
       sql:=sql+'`ID` int(5) NOT NULL auto_increment,';
       sql:=sql+'`zDate` datetime NOT NULL,';
       sql:=sql+'`package_name` varchar(255) NOT NULL,';
       sql:=sql+'`events` text NOT NULL,';
       sql:=sql+'`install_type` varchar(50) NOT NULL,';
       sql:=sql+'PRIMARY KEY  (`ID`),';
       sql:=sql+'KEY `package_name` (`package_name`),';
       sql:=sql+'KEY `install_type` (`install_type`)';
       sql:=sql+')';
       if not logs.QUERY_SQL(Pchar(sql),'artica_backup') then begin
          logs.Syslogs('tapt.CheckTable() unable to create table debian_packages');
          exit;
       end;
  end;
  
  
exit(true);

end;
//##############################################################################
procedure tapt.INSERT_DEB_PACKAGES();
var
   sql:string;
   RegExpr:TRegExpr;
   i:integer;
   l:TstringList;
   filetemp:string;
   content:string;
   pname:string;
   package_description:string;
   EnableMysqlFeatures:boolean;
begin
   EnableMysqlFeatures:=false;
   if not fileexists(sys.LOCATE_DPKG()) then begin
      logs.Syslogs('tapt.INSERT_DEB_PACKAGES() unable to stat dpkg');
      exit;
   end;
   
   if SYS.GET_INFO('EnableMysqlFeatures')='1' then EnableMysqlFeatures:=true;;
   if not EnableMysqlFeatures then exit;
   if not CheckTable() then exit;


   
logs.Syslogs('clear debian_packages table...');
sql:='TRUNCATE TABLE `debian_packages`';
logs.QUERY_SQL(Pchar(sql),'artica_backup');
filetemp:=logs.FILE_TEMP();
fpsystem(sys.LOCATE_DPKG() + ' -l >' + filetemp + ' 2>&1');
if not FileExists(filetemp) then begin
      logs.Syslogs('unable to stat '+filetemp);
      exit;
end;


l:=TstringList.Create;
l.LoadFromFile(filetemp);
logs.DeleteFile(filetemp);
RegExpr:=TRegExpr.Create;
RegExpr.Expression:='^([a-z]+)\s+(.+?)\s+(.+?)\s+(.+)';
for i:=0 to l.Count-1 do begin
   if not RegExpr.Exec(l.Strings[i]) then continue;
   content:=RegExpr.Match[4];
   content:=logs.GetAsSQLText(content);
   
   pname:=RegExpr.Match[2];
   package_description:=logs.GetAsSQLText(PACKAGE_EXTRA_INFO(pname));
   
   sql:='INSERT INTO debian_packages(package_status,package_name,package_version,package_info,package_description) ';
   sql:=sql+'VALUES("'+RegExpr.Match[1]+'","'+RegExpr.Match[2]+'","'+RegExpr.Match[3]+'","'+content+'","'+package_description+'")';
   logs.QUERY_SQL(Pchar(sql),'artica_backup');
end;

FreeAndNil(l);
FreeAndNil(RegExpr);


end;
//##############################################################################

function tapt.PACKAGE_EXTRA_INFO(package_name:string):string;
var

   filetemp:string;
begin
  if not FileExists(sys.LOCATE_DPKG_QUERY()) then exit;
  filetemp:=logs.FILE_TEMP();
  fpsystem(sys.LOCATE_DPKG_QUERY() + ' -p ' + package_name + ' >' +filetemp + ' 2>&1');
  if not FileExists(filetemp) then begin
      logs.Syslogs('unable to stat '+filetemp);
      exit;
  end;

result:=logs.ReadFromFile(filetemp);
logs.DeleteFile(filetemp);
end;
//##############################################################################
procedure tapt.UNSTALL_MARK();
var

   filetemp,SQL,pname:string;
   l:TstringList;
   s:TstringList;
   i:integer;
begin
if not FileExists(sys.LOCATE_APT_GET()) then exit;
SQL:='SELECT package_name FROM debian_packages WHERE package_status="a-uu"';
l:=TstringList.Create;
l.AddStrings(logs.QUERY_SQL_PARSE_COLUMN(sql,'artica_backup',0));
s:=TstringList.Create;
for i:=0 to l.Count-1 do begin
     pname:=l.Strings[i];
     filetemp:=logs.FILE_TEMP();
     fpsystem(sys.LOCATE_APT_GET() +' remove ' + pname + ' --yes --force-yes >>'+filetemp + ' 2>&1');
     if FileExists(filetemp) then begin
         s.LoadFromFile(filetemp);
         logs.DeleteFile(filetemp);
         SQL:='INSERT INTO debian_packages_logs(zDate,package_name,events,install_type) VALUES("'+logs.DateTimeNowSQL()+'","'+pname+'","'+logs.GetAsSQLText(s.Text)+'","uninstall")';
         logs.QUERY_SQL(pchar(SQL),'artica_backup');
         SQL:='UPDATE debian_packages SET package_status="rc" WHERE package_name="'+pname+'"';
         logs.QUERY_SQL(pchar(SQL),'artica_backup');
     end;

end;


FreeAndNil(l);
FreeAndNil(s);
end;
//##############################################################################
procedure tapt.INSTALL_MARK();
var

   filetemp,SQL,pname:string;
   l:TstringList;
   s:TstringList;
   i:integer;
   cmd:string;
begin
if not FileExists(sys.LOCATE_APT_GET()) then exit;
SQL:='SELECT package_name FROM debian_packages WHERE package_status="a-ii"';
l:=TstringList.Create;
l.AddStrings(logs.QUERY_SQL_PARSE_COLUMN(sql,'artica_backup',0));
s:=TstringList.Create;
for i:=0 to l.Count-1 do begin
     pname:=l.Strings[i];
     filetemp:=logs.FILE_TEMP();
     cmd:='DEBIAN_FRONTEND=noninteractive '+sys.LOCATE_APT_GET()+' -o Dpkg::Options::="--force-confnew" --force-yes -fuy install ' + pname + ' >>'+filetemp + ' 2>&1';
     logs.Debuglogs(cmd);
     fpsystem(cmd);
     if FileExists(filetemp) then begin
         s.LoadFromFile(filetemp);
         logs.DeleteFile(filetemp);
         SQL:='INSERT INTO debian_packages_logs(zDate,package_name,events,install_type) VALUES("'+logs.DateTimeNowSQL()+'","'+pname+'","'+logs.GetAsSQLText(s.Text)+'","install")';
         logs.QUERY_SQL(pchar(SQL),'artica_backup');
         SQL:='UPDATE debian_packages SET package_status="ii" WHERE package_name="'+pname+'"';
         logs.QUERY_SQL(pchar(SQL),'artica_backup');
     end;

end;


FreeAndNil(l);
FreeAndNil(s);
end;
//##############################################################################
procedure tapt.FIND(pattern:string);
var
filetemp:string;
begin
filetemp:=logs.FILE_TEMP();
fpsystem(sys.LOCATE_APT_CACHE() + ' search ' + pattern + ' >'+filetemp + ' 2>&1');
writeln(logs.ReadFromFile(filetemp));
end;
//##############################################################################
procedure tapt.INFO(pattern:string);
var
filetemp:string;
begin
filetemp:=logs.FILE_TEMP();
fpsystem(sys.LOCATE_APT_CACHE() + ' show ' + pattern + ' >'+filetemp + ' 2>&1');
writeln(logs.ReadFromFile(filetemp));
end;
//##############################################################################
procedure tapt.Check();
var
filetemp:string;
RegExpr:TRegExpr;
   i:integer;
   l:TstringList;
   s:TstringList;
   count:integer;
begin
if not SYS.croned_minutes2(180) then exit;
CheckTable();
filetemp:=logs.FILE_TEMP();
if not FIleExists(sys.LOCATE_APT_GET()) then begin
   logs.Debuglogs('tapt.Check():: unable to stat apt-get');
   exit;
end;

logs.OutputCmd(sys.LOCATE_APT_GET() + ' update');
logs.OutputCmd(sys.LOCATE_APT_GET() + ' -f install --force-yes');
logs.Debuglogs(sys.LOCATE_APT_GET() + ' upgrade -s >'+filetemp + ' 2>&1');
fpsystem(sys.LOCATE_APT_GET() + ' upgrade -s >'+filetemp + ' 2>&1');
if not fileExists(filetemp) then exit;

l:=TstringList.Create;
l.LoadFromFile(filetemp);
RegExpr:=TRegExpr.Create;
RegExpr.Expression:='^Inst\s+(.+?)\s+';
s:=TstringList.Create;
for i:=0 to l.Count-1 do begin
    if RegExpr.Exec(l.Strings[i]) then begin
         count:=count+1;
         s.Add(RegExpr.Match[1]);
    end else begin
        //writeln(l.Strings[i],' not');
    end;
end;
if count>0 then begin
   s.Insert(0,'nb:'+IntTostr(count) + ' packages');
   logs.NOTIFICATION('[ARTICA]: ('+SYS.HOSTNAME_g()+') new upgrade '+ IntTostr(count)+' package(s) ready','You can perform upgrade of linux packages for ' + SYS.HOSTNAME_g(),'system');
   forceDirectories('/etc/artica-postfix');
   s.SaveToFile('/etc/artica-postfix/apt.upgrade.cache');
end else begin
   logs.DeleteFile('/etc/artica-postfix/apt.upgrade.cache');
end;

   s.Free;
   l.free;
   RegExpr.free;
end;
//##############################################################################
procedure tapt.upgrade();
var
filetemp,cmd,sql,tmpstr:string;
begin
filetemp:=logs.FILE_TEMP();
if not FIleExists(sys.LOCATE_APT_GET()) then begin
   logs.Debuglogs('tapt.upgrade():: unable to stat apt-get');
   exit;
end;

fpsystem('PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/X11R6/bin');
fpsystem('echo $PATH >'+filetemp + ' 2>&1');
fpsystem(cmd);
logs.Debuglogs(logs.ReadFromFile(filetemp));

cmd:='DEBIAN_FRONTEND=noninteractive '+sys.LOCATE_APT_GET()+' -o Dpkg::Options::="--force-confnew" --force-yes update >'+filetemp + ' 2>&1';
fpsystem(cmd);
logs.Debuglogs(cmd);



cmd:='DEBIAN_FRONTEND=noninteractive '+sys.LOCATE_APT_GET()+' -o Dpkg::Options::="--force-confnew" --force-yes --yes install -f >>'+filetemp + ' 2>&1';
logs.Debuglogs(cmd);
fpsystem(cmd);



cmd:='DEBIAN_FRONTEND=noninteractive '+sys.LOCATE_APT_GET()+' -o Dpkg::Options::="--force-confnew" --force-yes --yes upgrade >>'+filetemp + ' 2>&1';
logs.Debuglogs(cmd);
fpsystem(cmd);



cmd:='DEBIAN_FRONTEND=noninteractive '+sys.LOCATE_APT_GET()+' -o Dpkg::Options::="--force-confnew" --force-yes --yes dist-upgrade >>'+filetemp + ' 2>&1';
logs.Debuglogs(cmd);
fpsystem(cmd);
logs.Debuglogs(logs.ReadFromFile(filetemp));

if not fileExists(filetemp) then exit;
tmpstr:=logs.ReadFromFile(filetemp);
tmpstr:=logs.GetAsSQLText(tmpstr);

SQL:='INSERT INTO debian_packages_logs(zDate,package_name,events,install_type) VALUES("'+logs.DateTimeNowSQL()+'","artica-upgrade","'+tmpstr+'","upgrade")';
//logs.Debuglogs(SQL);
logs.QUERY_SQL(pchar(SQL),'artica_backup');
logs.DeleteFile('/etc/artica-postfix/apt.upgrade.cache');
Check();
INSERT_DEB_PACKAGES();
end;
//##############################################################################




end.
