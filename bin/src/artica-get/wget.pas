unit wget;
{$MODE DELPHI}
//{$mode objfpc}{$H+}
{$LONGSTRINGS ON}

interface

uses
Classes, SysUtils,strutils,RegExpr in 'RegExpr.pas',curlobj;
type
  TStringDynArray = array of string;

  type
  Twget=class


private
     UseProxy:string;
     ProxyUser:string;
     ProxyPasswd:string;
     ProxyName:string;
     ProxyPort:string;
     TargetFile:string;
     uri:string;
     D:Boolean;
     function COMMANDLINE_EXTRACT_PARAMETERS():string;
     function COMMANDLINE_PARAMETERS(FoundWhatPattern:string):boolean;
     function help():string;
public
      function GetFile():boolean;
      constructor Create();
      destructor Destroy;virtual;

END;

implementation

constructor Twget.Create();
begin
end;

destructor Twget.Destroy;
begin
  inherited Destroy;
end;

function Twget.GetFile():boolean;
var
    MyCurl:tCurl;
   l: tstringlist;
begin

   if ParamCount=0 then begin
      help();
      exit;
   end;
   MyCurl:=tCurl.Create(nil);
   l:=tstringlist.Create;
   UseProxy:='no';
   ProxyUser:='';
   D:=true;

   COMMANDLINE_EXTRACT_PARAMETERS();
   if length(uri)=0 then begin
      if D then writeln('no uri submitted');
      help();
      exit();
   end;
   
   

   
   if UseProxy='on' then begin
      if d then writeln('use proxy ' + ProxyName + ':' + ProxyPort + '--> ' + ProxyUser);
      if length(ProxyUser)>0 then begin
            if length(ProxyPasswd)>0 then ProxyUser:=ProxyUser+':'+ProxyPasswd;
      end;
      
      if length(ProxyUser)>0 then  mycurl.Proxy:='http://' + ProxyUser + '@'+ProxyName + ':' + ProxyPort;
      if length(ProxyUser)=0 then  mycurl.Proxy:='http://' + ProxyName + ':' + ProxyPort;
      
      
   end else begin
       if d then Writeln('no proxy to use...');
   
   end;

   if d then writeln('get ' + uri);
   if d then writeln('Save to file  ' + TargetFile);
     
   MyCurl.URL:=uri;
   MyCurl.OutputFile:=TargetFile;
   MyCurl.NoProgress:=True;
   MyCurl.ProgressData:=nil;
   MyCurl.FollowLocation:=True;
   
   if not MyCurl.Perform then begin
      if D then WriteLn(MyCurl.ErrorString);
      
   end;
   



end;

//##############################################################################
function Twget.help():string;
begin
   writeln('');
   writeln('usage artica-wget [options] [url]');
   writeln;
   writeln('Proxy usages');
   writeln('------------------------------------------------------------');
   writeln('--proxy=(on|off).................:Enable HTTP proxy support');
   writeln('--proxy-user=....................:HTTP Proxy username');
   writeln('--proxy-passwd=..................:HTTP Proxy password');
   writeln('--proxy-name=address:port........:HTTP Proxy address + port');
   writeln;
   writeln('download usages');
   writeln('------------------------------------------------------------');
   writeln('-q:..............................:Quiet mode');
   writeln('--output-document=:..............:Save File to full path');
   writeln;
   
end;


function Twget.COMMANDLINE_EXTRACT_PARAMETERS():string;
var
   i:integer;
   s:string;
   RegExpr:TRegExpr;
   path,myParam:string;
   Z:boolean;
begin
 result:='';
 z:=COMMANDLINE_PARAMETERS('--verbose');
 
  if ParamCount>0 then begin
     for i:=1 to ParamCount do begin
        myParam:=myParam  + ' ' +ParamStr(i);
     end;
 end;
 
 if z then writeln('Parameters:',ParamCount);
 if z then writeln('Command lines:',myParam);
 

 
 if ParamCount>0 then begin
     for i:=1 to ParamCount do begin
        s:=ParamStr(i);
        if z then writeln(s);

         RegExpr:=TRegExpr.Create;
         RegExpr.Expression:='--proxy=(on|off)';
         if RegExpr.Exec(s) then UseProxy:=RegExpr.Match[1];

         RegExpr.Expression:='--proxy-user=(.+)';
         if RegExpr.Exec(s) then ProxyUser:=RegExpr.Match[1];

         RegExpr.Expression:='--proxy-passwd=(.+)';
         if RegExpr.Exec(s) then ProxyPasswd:=RegExpr.Match[1];
         
         RegExpr.Expression:='--proxy-name=(.+?):([0-9]+)';
         if RegExpr.Exec(s) then begin
            ProxyName:=RegExpr.Match[1];
            ProxyPort:=RegExpr.Match[2];
         end;
            

         RegExpr.Expression:='--output-document=(.+)';
         if RegExpr.Exec(s) then TargetFile:=RegExpr.Match[1];
         
         RegExpr.Expression:='-q';
         if RegExpr.Exec(s) then D:=false;
         
         RegExpr.Expression:='http://';
         if RegExpr.Exec(s) then uri:=ParamStr(i);
         
         

         end;
 end;
if length(TargetFile)=0 then begin
          if Z then writeln('no --output-document token, get default file');
           TargetFile:=ExtractFilePath(ParamStr(0)) +  ExtractFileName(uri);
         end;
         RegExpr.Free;
end;
//##############################################################################
function Twget.COMMANDLINE_PARAMETERS(FoundWhatPattern:string):boolean;
var
   i:integer;
   s:string;
   RegExpr:TRegExpr;

begin
 result:=false;
 if ParamCount>0 then begin
     for i:=1 to ParamCount do begin
        s:=s  + ' ' +ParamStr(i);
     end;
 end else begin
 
 exit;
 end;
   RegExpr:=TRegExpr.Create;
   RegExpr.Expression:=FoundWhatPattern;
   if RegExpr.Exec(s) then begin
      RegExpr.Free;
      result:=True;
   end;


end;
end.

