unit miltergreylist;

{$MODE DELPHI}
{$LONGSTRINGS ON}

interface

uses
    Classes, SysUtils,variants,strutils,Process,logs,unix,RegExpr in 'RegExpr.pas',zsystem;

  type
  tmilter_greylist=class


private
     LOGS:Tlogs;
     SYS:TSystem;
     artica_path:string;
     why_is_disabled:string;
     EnableASSP:integer;
     MilterGreyListEnabled:integer;
     MilterGreyListEnabled_string:string;
     EnablePostfixMultiInstance:integer;
     EnableStopPostfix:integer;


public
    procedure   Free;
    constructor Create(const zSYS:Tsystem);
    //function    STATUS:string;



    procedure   MILTER_GREYLIST_START();

    function    MILTER_GREYLIST_INITD():string;
    function    MILTER_GREYLIST_CONF_PATH():string;
    function    MILTER_GREYLIST_BIN_PATH():string;



    procedure   MILTER_GREYLIST_STOP();




    procedure   REMOVE();
END;

implementation

constructor tmilter_greylist.Create(const zSYS:Tsystem);
begin
       forcedirectories('/etc/artica-postfix');
       forcedirectories('/opt/artica/tmp');
       LOGS:=tlogs.Create();
       SYS:=zSYS;
       MilterGreyListEnabled:=0;
       EnablePostfixMultiInstance:=0;
       MilterGreyListEnabled_string:=trim(SYS.GET_INFO('MilterGreyListEnabled'));
       if MilterGreyListEnabled_string='1' then MilterGreyListEnabled:=1;

       if not TryStrToInt(SYS.GET_INFO('EnableASSP'),EnableASSP) then EnableASSP:=0;
       if not FileExists('/usr/share/assp/assp.pl') then EnableASSP:=0;
       if not TryStrToInt(SYS.GET_INFO('EnablePostfixMultiInstance'),EnablePostfixMultiInstance) then EnablePostfixMultiInstance:=0;
       if not TryStrToInt(SYS.GET_INFO('EnableStopPostfix'),EnableStopPostfix) then EnableStopPostfix:=0;

       if EnableStopPostfix=1 then MilterGreyListEnabled:=0;

       if MilterGreyListEnabled=1 then begin
          if EnableASSP=1 then begin
             why_is_disabled:=' ASSP do the same feature';
             MilterGreyListEnabled:=0;
          end;

          if EnablePostfixMultiInstance=1 then begin
             why_is_disabled:='multiple postfix instances enabled';
             MilterGreyListEnabled:=0;
             //logs.Debuglogs('tmilter_greylist.Create() :: Postfix multiple instance is enabled, disable milter-greylist');
          end;
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
procedure tmilter_greylist.free();
begin
    logs.Free;


end;
//##############################################################################
procedure tmilter_greylist.REMOVE();
begin
MILTER_GREYLIST_STOP();
fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --remove milter-greylist');
logs.DeleteFile(MILTER_GREYLIST_BIN_PATH());
logs.DeleteFile(MILTER_GREYLIST_INITD());
fpsystem(SYS.LOCATE_PHP5_BIN()+' /usr/share/artica-postfix/exec.main-cf.php --reconfigure');
logs.DeleteFile('/etc/artica-postfix/versions.cache');
fpsystem('/usr/share/artica-postfix/bin/artica-install --write-versions');
fpsystem('/usr/share/artica-postfix/bin/process1 --force');

end;
 //##############################################################################

function tmilter_greylist.MILTER_GREYLIST_INITD():string;
begin
    if FileExists('/etc/init.d/milter-greylist') then exit('/etc/init.d/milter-greylist');
    if FileExists('/etc/init.d/milter-greylist') then exit('/etc/init.d/milter-greylist');
end;
//############################################################################# #
function tmilter_greylist.MILTER_GREYLIST_CONF_PATH():string;
begin
if FileExists('/etc/milter-greylist/greylist.conf') then exit('/etc/milter-greylist/greylist.conf');
if FileExists('/etc/mail/greylist.conf') then exit('/etc/mail/greylist.conf');
if FileExists('/opt/artica/etc/milter-greylist/greylist.conf') then exit('/opt/artica/etc/milter-greylist/greylist.conf');
exit('/etc/mail/greylist.conf');
end;
 //##############################################################################
 function tmilter_greylist.MILTER_GREYLIST_BIN_PATH():string;
begin
result:=sys.LOCATE_GENERIC_BIN('milter-greylist');
end;
 //##############################################################################
 procedure tmilter_greylist.MILTER_GREYLIST_STOP();
 var
    count:integer;
    processes:string;
begin
count:=0;
  if not FileExists(MILTER_GREYLIST_BIN_PATH()) then exit;

    if EnablePostfixMultiInstance=1 then begin
       fpsystem(SYS.LOCATE_PHP5_BIN() +' /usr/share/artica-postfix/exec.milter-greylist.php --stop');
       exit;
    end;
    fpsystem(SYS.LOCATE_PHP5_BIN()+' /usr/share/artica-postfix/exec.milter-greylist.php --stop-single');
end;
//############################################################################
procedure tmilter_greylist.MILTER_GREYLIST_START();
var

   socketPath:string;
   user:string;
   pid_path:string;
   pid_dir:string;
   FullSocketPath:string;
begin

    logs.Debuglogs('############### MILTER-GREYLIST ################################');
    

    if not FileExists(MILTER_GREYLIST_BIN_PATH()) then begin
       logs.Debuglogs('Starting......: milter-greylist is not installed');
       exit;
    end;

    if EnablePostfixMultiInstance=1 then begin
       fpsystem(SYS.LOCATE_PHP5_BIN() +' /usr/share/artica-postfix/exec.milter-greylist.php --start');
       exit;
    end;
    logs.Debuglogs('MILTER_GREYLIST_START:: MilterGreyListEnabled_string -> "' + MilterGreyListEnabled_string+'" MilterGreyListEnabled="'+IntToStr(MilterGreyListEnabled) +'" EnableASSP="'+IntToStr(EnableASSP)+'" EnablePostfixMultiInstance="'+IntToStr(EnablePostfixMultiInstance)+'"');
    if MilterGreyListEnabled=0 then begin
       logs.Debuglogs('Starting......: milter-greylist is disabled by artica ('+why_is_disabled+')');
       exit;
    end;

    fpsystem(SYS.LOCATE_PHP5_BIN()+' /usr/share/artica-postfix/exec.milter-greylist.php --start-single');
end;
end.
