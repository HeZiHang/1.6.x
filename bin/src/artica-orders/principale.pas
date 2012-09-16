unit principale;
{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,variants, Process,unix,logs,
  RegExpr,zsystem,
  global_conf in 'global_conf.pas';
type
  torders=class
  private
       procedure ParseLocalQueue();
       function  SaveInqueue(Order:string):boolean;
       logs:Tlogs;
       final:Tstringlist;
       SYS:Tsystem;
  public

    constructor Create;
    end;

implementation

constructor torders.Create;
begin
 LOGS:=Tlogs.Create;
 final:=tstringlist.Create;
 SYS:=Tsystem.Create();
 ParseLocalQueue();
end;

//##############################################################################
procedure torders.ParseLocalQueue();
var
   l:TstringList;
   nice:string;
   i:Integer;
   sh:TstringList;
   save:boolean;
   executed:boolean;
begin
    save:=false;
    sh:=TstringList.Create;
    sh.Add('#!/bin/sh');
    sh.Add('PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/bin/X11');
    sh.Add('export PATH');
    if FileExists('/etc/artica-postfix/orders.queue') then begin
       l:=TstringList.Create;
       nice:=SYS.EXEC_NICE();
       l.LoadFromFile('/etc/artica-postfix/orders.queue');
       LOGS.Debuglogs('ParseLocalQueue() ' + intToStr(l.Count) + ' orders in /etc/artica-postfix/orders.queue');
    
       for i:=0 to l.Count -1 do begin
           if SaveInqueue(l.Strings[i]) then begin
              LOGS.Syslogs('Execute in background:: "' +l.Strings[i] + '"');
              sh.Add(nice+l.Strings[i]+' &');
              save:=true;
           end;
        end;

        l.free;
        logs.DeleteFile('/etc/artica-postfix/orders.queue');
     end else begin
      logs.Debuglogs('No orders in /etc/artica-postfix/orders.queue');
     
     end;
     
     
    executed:=false;
    if FileExists('/etc/artica-postfix/background') then begin
       nice:=SYS.EXEC_NICE();
       l:=TstringList.Create;
       l.LoadFromFile('/etc/artica-postfix/background');

       LOGS.Debuglogs('ParseLocalQueue() ' + intToStr(l.Count) + ' orders in /etc/artica-postfix/background');

       if l.Count>0 then logs.Syslogs('Executing '+intToStr(l.Count) + ' orders');

       for i:=0 to l.Count -1 do begin
         if length(trim(l.Strings[i]))=0 then begin
            logs.Syslogs('Order ' + IntTostr(i) +' is empty');
            continue;
         end else begin
             logs.Syslogs('Executing '+nice+l.Strings[i]+' &');
             fpsystem(nice+l.Strings[i]+' &');
             executed:=true;
             l.Delete(i);
             break;
         end;
       end;

       if executed then begin
         logs.Syslogs('updating orders /etc/artica-postfix/background');
         logs.WriteToFile(l.Text,'/etc/artica-postfix/background');
       end else begin
          logs.DeleteFile('/etc/artica-postfix/background');
       end;



       l.free;
    end else begin
       logs.Debuglogs('No orders in /etc/artica-postfix/background');
    end;





end;
//##############################################################################
function torders.SaveInqueue(Order:string):boolean;
var
   smd:string;
   i:integer;
begin
   result:=false;
   smd:=logs.MD5FromString(Order);
   for i:=0 to final.Count-1 do begin
     if final.Strings[i]=smd then begin
         exit(false);
         break;
     end;
   end;
   
 final.Add(smd);
 result:=true;
   
end;
//##############################################################################
   

end.

