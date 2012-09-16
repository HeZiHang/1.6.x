unit dar_events;
{$MODE DELPHI}
{$LONGSTRINGS ON}

interface

uses
    Classes, SysUtils,variants,strutils,IniFiles, Process,md5,logs,unix,RegExpr in 'RegExpr.pas',zsystem;

type darevent=record
      ressource:string;
      started_on:string;
      finish_on:string;
      error:string;
      failed:string;
      xml:string;
      db_path:string;
  end;

  type
  tdar_events=class


private
     LOGS:Tlogs;
     iniev:TiniFIle;
     SYS:Tsystem;


public
      x_events:darevent;
      procedure   Free;
      constructor Create;
      procedure SetStart();
      procedure SetRessource(ressource:string);
      procedure SetEnd();
      procedure SetFailed();
      procedure SetError(error:string);
      procedure SetDatabasePath(path:string);
      procedure SetXML(path:string);
      procedure Build();
end;

implementation

constructor tdar_events.Create;
begin

       LOGS:=tlogs.Create();
       SYS:=Tsystem.Create;


end;
//##############################################################################
procedure tdar_events.free();
begin
    logs.Free;
    SYS.Free;


end;
//##############################################################################
procedure tdar_events.SetStart();
begin
   x_events.started_on:=logs.DateTimeNowSQL();
end;
//##############################################################################
procedure tdar_events.SetEnd();
begin
   x_events.finish_on:=logs.DateTimeNowSQL();
end;
//##############################################################################
procedure tdar_events.SetError(error:string);
begin
   logs.Debuglogs(error);
   x_events.error:=error;
   SetFailed();
   SetEnd();
   Build();
end;
//##############################################################################
procedure tdar_events.SetRessource(ressource:string);
begin
   x_events.ressource:=ressource;
end;
//##############################################################################
procedure tdar_events.SetFailed();
begin
   x_events.failed:='1';
end;
//##############################################################################
procedure tdar_events.SetXML(path:string);
begin
   x_events.xml:=path;
end;
//##############################################################################
procedure tdar_events.SetDatabasePath(path:string);
begin
   x_events.db_path:=path;
end;
//##############################################################################
procedure tdar_events.Build();
var
   l:TstringList;
   queue_file:string;

begin

queue_file:='/var/log/artica-postfix/dar-queue/'+ logs.MD5FromString(logs.DateTimeNowSQL()+x_events.ressource+x_events.started_on)+'.queue';
ForceDirectories('/var/log/artica-postfix/dar-queue');

l:=Tstringlist.Create;
SetEnd();
if x_events.failed='' then x_events.failed:='0';
   l:=Tstringlist.Create;
   l.Add('[INCREMENTAL]');
   l.Add('ressource='+x_events.ressource);
   l.Add('started_on='+x_events.started_on);
   l.Add('finish_on='+x_events.finish_on);
   l.Add('failed='+x_events.failed);
   l.Add('error='+x_events.error);
   l.Add('db_path='+x_events.db_path);
   l.Add('xml='+x_events.xml);
   logs.WriteToFile(l.Text,queue_file);
   l.free;

    x_events.ressource:='';
    x_events.started_on:='';
    x_events.finish_on:='';
    x_events.failed:='';
    x_events.error:='';
    x_events.xml:='';
    x_events.db_path:='';
end;
//##############################################################################





end.

