program articacgi;

uses dos,baseUnix,unix,Classes, SysUtils,global_conf,parsehttp,logs,RegExpr in 'RegExpr.pas',
  users;


var
   //data : array[1..max_data] of datarec;
    i : longint;
    zLOGS:tlogs;
    ParsHTTP:Tparsehttp;
    zRegExpr:TRegExpr;

begin


     zLOGS:=tlogs.Create;
     zLOGS.logs('articacgi:: QUERY_STRING=' + getenv('QUERY_STRING'));
     zLOGS.logs('articacgi:: REMOTE_ADDR=' + getenv('REMOTE_ADDR'));

     ParsHTTP:=Tparsehttp.Create;




     writeln ('Content-type: text/html');
     writeln;
     writeln('<html><head></head><body>');
     writeln('<articadatascgi>');
     zRegExpr:=TRegExpr.Create;
     zRegExpr.Expression:='URI=(.+)';
     if zRegExpr.Exec(getenv('QUERY_STRING')) then begin
          ParsHTTP.ParseUri(zRegExpr.Match[1]);
          zLOGS.logs('articacgi::response  ' + IntToStr(ParsHTTP.FileData.Count) + ' lines');
          for i:=0 to ParsHTTP.FileData.Count-1 do begin
              writeln(ParsHTTP.FileData.Strings[i]);
          end;
     
     end;
 zRegExpr.Free;
 ParsHTTP.free;
writeln('</articadatascgi>');
writeln('<body></html>');




end.
