program articapolicy;


uses
  cthreads,linux,BaseUnix,oldlinux,Dos,Classes,SysUtils, logs,PolicySocket,filter,RegExpr in 'RegExpr.pas';
   //inet_thread_daemon
var
   i:integer;
   xLOGS:Tlogs;
   s:string;
   bHup,bTerm : boolean;
   fLog : text;
   logname : string;
   aOld,aTerm,aHup : pSigActionRec;
   ps1  : psigset;
   sSet : cardinal;
   pid : longint;
   secs : longint;
   hr,mn,sc,sc100 : word;
   parameters:string;
   str_pid:string;
   debug:boolean;
   scount:integer;
   xf:tfilter;
   xa:TstringList;

{ handle SIGHUP & SIGTERM }
{ keep this code small! }
procedure DoSig(sig : longint);cdecl;
begin
   case sig of
      SIGHUP : bHup := true;
      SIGTERM : bTerm := true;
   end;
end;

{ create the pid file }
function CreatePID:boolean;
Var       F : Text;
          myFile : TextFile;
          TargetPath:string;
          T:TstringList;
          R:TRegExpr;
          PIDS:string;
begin
result:=false;
forcedirectories('/etc/artica-postfix');
TargetPath:='/etc/artica-postfix/artica-policy.pid';
PIDS:=intTostr(getpid);

    XLOGS.logs('artica-policy:: PID number ' + PIDS);

if PIDS='0' then begin
   XLOGS.logs('artica-policy:: Bad pId ' + PIDS);
   exit();
end;


 if FileExists(TargetPath) then begin
    T:=TstringList.Create;
    T.LoadFromFile(TargetPath);
    R:=TRegExpr.Create;
    R.Expression:='([0-9]+)';
    R.Exec(trim(T.Text));
    XLOGS.logs('artica-policy:: read old pid ' + R.Match[1] );
    if FileExists('/proc/' + R.Match[1] + '/exe') then begin
        XLOGS.logs('artica-policy:: process already exists ' + R.Match[1] );
        writeln('Error: Process ' + R.Match[1] + ' already running');
        T.Clear;T.free;
        R.Free;
        halt(0);
        exit(false);
    end;
    T.Clear;T.free;
    R.Free;
 end;
    
    TRY
       AssignFile(myFile, TargetPath);
       ReWrite(myFile);
       WriteLn(myFile, PIDS);
       CloseFile(myFile);
       XLOGS.logs('artica-policy:: sucess writing pid  ' + PIDS );
       exit(true);
    EXCEPT
          writeln('Error: writing pid file' +     TargetPath);
    END;

End;


procedure StartOperations;
begin
     XLOGS.logs('artica-policy:: starting daemon');
     if CreatePID()=false then begin
        XLOGS.logs('artica-policy:: failed initialize' );
        halt(0);
     end else begin
         XLOGS.logs('artica-policy:: success initialize start server' );
         TTCPEchoDaemon.Create;
     end;
     
     
end;
function IsRoot():boolean;
begin
if GetEUid=0 then exit(true);
exit(false);
end;




begin
debug:=False;
secs := 10;
XLOGS:=TLogs.Create;
    if IsRoot()=false then begin
        writeln('This program wust run as root');
        halt(0);
    end;


    if paramStr(1)='no-daemon' then begin
          TTCPEchoDaemon.Create;
          readln();
          halt(0);
    end;

if paramStr(1)='scan' then begin
          xf:=TFilter.Create;
          xa:=TStringList.Create;
          xa.LoadFromFile(paramStr(2));
          xf.ParseLines(xa.Text);
          halt(0);
    end;





   { set global daemon booleans }
   bHup := true; { to open log file }
   bTerm := false;

   { block all signals except -HUP & -TERM }
   sSet := $ffffbffe;
   ps1 := @sSet;
   sigprocmask(sig_block,ps1,nil);

   { setup the signal handlers }
   new(aOld);
   new(aHup);
   new(aTerm);
   { v1.0 changed the structure of SigActionRec }
   {$ifdef VER0 }
   aTerm^.sa_handler := @DoSig;
   aHup^.sa_handler := @DoSig;
   {$else}
   aTerm^.handler.sh := @DoSig;
   aHup^.handler.sh := @DoSig;
   {$endif}
   aTerm^.sa_mask := 0;
   aTerm^.sa_flags := 0;
   aTerm^.sa_restorer := nil;
   aHup^.sa_mask := 0;
   aHup^.sa_flags := 0;
   aHup^.sa_restorer := nil;
   SigAction(SIGTERM,aTerm,aOld);
   SigAction(SIGHUP,aHup,aOld);


   { daemonize }
   pid := Fork;
   Case pid of
      0 : Begin { we are in the child }
         {$ifdef VER1_00_0 }
         writeln('WARNING:');
         writeln('Please upgrade your compiler to a later snapshot.');
         writeln('v1.00 contains a bug in the system unit relative to');
         writeln('using /dev/null.');
         writeln('input, output, and stderr have not been re-directed.');
         {$else}
         if debug=false then begin
            Close(input);  { close standard in }
            Close(output); { close standard out }
            Assign(output,'/dev/null');
            ReWrite(output);
            Close(stderr); { close standard error }
            Assign(stderr,'/dev/null');
            ReWrite(stderr);
         end;
         {$endif}
      End;
      -1 : secs := 0;     { forking error, so run as non-daemon }
      Else Halt;          { successful fork, so parent dies }
   End;


        StartOperations;
   { begin processing loop }
   If secs > 0 Then
   Repeat
      writeln('bHup -> ',bHup);
      If bHup Then Begin
         {$I-}
         IoResult;
         {$I+}
         bHup := false;
      End;


      If not bTerm Then
         { wait a while }
         Select(0,nil,nil,nil,secs*1000);



   Until bTerm;
         scount:=0;
         XLOGS.logs('artica-policy: Free threads and terminate daemon...');
         halt(0);
end.


