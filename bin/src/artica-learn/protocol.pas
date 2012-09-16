unit protocol;

{$MODE DELPHI}
//{$mode objfpc}{$H+}
{$LONGSTRINGS ON}

interface

uses
Classes, SysUtils,variants,IniFiles, md5,RegExpr in 'RegExpr.pas',logs,strutils,ldap;
type
  TStringDynArray = array of string;
  type
  Tprotocol=class




private
     function MD5FromString(values:string):string;
     function protocole_prepare_mail():string;
     function ParseMultipleDatas(receive:string):string;
     procedure VerifyDupMailTo(email_to:string);
     function ArticaFilterQueuePath():string;
     function CountFiles(QueuePath:string):integer;
     QUEUE_PATH:string;
     MAIL_FROM:string;
     MAIL_SIZE:string;
     BODY_TYPE:string;
     MESSAGE_BODY:string;

public
    RECEIVE_DATA:boolean;
    RECEIVE_QUIT:boolean;
    constructor Create;
    procedure Free;
    function ParseProtocol(receive:string):string;
    function Explode(const Separator, S: string; Limit: Integer = 0):TStringDynArray;
    function ParseProtocolTable(receive:String):string;
    LIST:TStringList;
    HEAD:TstringList;
    MAILTO_LIST:TStringList;
    function ParseDatas(receive:string):string;
    function get_ARTICA_PHP_PATH():string;
    function MyProtocol(receive:String):string;
    destructor Destroy; override;
    procedure Clean;
    MESSAGE_IDA:string;
    
end;



implementation

//-------------------------------------------------------------------------------------------------------


//##############################################################################
constructor Tprotocol.Create;

begin
  forcedirectories('/etc/artica-postfix');
   HEAD:=TStringList.Create;
   LIST:=TStringList.Create;
   MAILTO_LIST:=TStringList.Create;
   RECEIVE_QUIT:=false;
   RECEIVE_DATA:=false;
   MESSAGE_IDA:='';
   QUEUE_PATH:=ArticaFilterQueuePath() + '/queue';
   MAIL_FROM:='';

end;
//##############################################################################
destructor Tprotocol.Destroy;
begin
  inherited Destroy;
end;


PROCEDURE Tprotocol.Free();
begin
   MAIL_FROM:='';
   MESSAGE_BODY:='';
end;
//##############################################################################
PROCEDURE Tprotocol.Clean();
var LOGS:Tlogs;

begin
logs:=TLogs.Create;
   if length(MESSAGE_IDA)>0 then begin
   TRY
      logs.logs('Tprotocol.Clean()::[' + MESSAGE_IDA + '] Clean memory' );
      if Assigned(LIST) then  LIST.Clear;
      RECEIVE_QUIT:=false;
      RECEIVE_DATA:=false;
      MESSAGE_IDA:='';
      logs.logs('Tprotocol.Clean()::[' + MESSAGE_IDA + '] End Clean memory' );
   Except
     logs.logs('Tprotocol.Clean()::[' + MESSAGE_IDA + ']  Error while cleaning memory' );
   end;
end;
   
   logs.Free;
end;
//##############################################################################
function Tprotocol.ArticaFilterQueuePath():string;
var ini:TIniFile;
begin
 ini:=TIniFile.Create('/etc/artica-postfix/artica-filter.conf');
 result:=ini.ReadString('INFOS','QueuePath','');
 if length(trim(result))=0 then result:='/usr/share/artica-filter';
end;
//##############################################################################

function Tprotocol.ParseDatas(receive:string):string;
         const
            CR = #$0d;
            LF = #$0a;
            CRLF = CR + LF;
      var
        RegExpr:TRegExpr;
        response:string;
        LOGS:Tlogs;
        ENDOFMAIL:integer;
        Table:TStringDynArray;
        i:integer;

BEGIN
if length(MESSAGE_IDA)=0 then MESSAGE_IDA:=MD5FromString(receive);

     try
     Table:=Explode(CRLF,receive);
     EXCEPT
      logs.ERRORS('artica-filter:: ParseDatas::[' + MESSAGE_IDA + '] error while explode datas line 131...');
     end;
     
     
    if length(Table)>1 then begin
       logs.FRee;
       exit(ParseMultipleDatas(receive))
    end;
    
    
    
    TRY
   

        if receive='.' +CRLF then  begin
           RECEIVE_DATA:=false;
           //logs.logs('ParseDatas::[' + MESSAGE_IDA + '] "' + IntToStr(LIST.Count) + '" rows OK Save to stream mail data..');
           exit(protocole_prepare_mail());
        end;
        //logs.logs('ParseDatas::[' + MESSAGE_IDA + '] continue accept datas..."' + IntToStr(LIST.Count) + '" rows now');
        list.Add(trim(receive));
   EXCEPT
      logs.ERRORS('ParseDatas::' + MESSAGE_IDA );
   end;

   

    logs.Free;
    

end;
//##############################################################################
function Tprotocol.ParseMultipleDatas(receive:string):string;
         const
            CR = #$0d;
            LF = #$0a;
            CRLF = CR + LF;
      var
        RegExpr:TRegExpr;
        response:string;
        LOGS:Tlogs;
        ENDOFMAIL:integer;
        Table:TStringDynArray;
        i:integer;
        DOWN_FROM:integer;
        DOWN_TO:integer;
        MyLog:string;

BEGIN
    RECEIVE_QUIT:=false;
    LOGS:=Tlogs.create;
    ENDOFMAIL:=0;
    DOWN_FROM:=0;
    DOWN_TO:=0;

if length(MESSAGE_IDA)=0 then MESSAGE_IDA:=MD5FromString(receive);

TRY
    Table:=Explode(CRLF,receive);

    DOWN_FROM:=length(Table)-1;
        if length(Table)>5 then begin
           DOWN_TO:=length(Table)-5;
        end else begin
            DOWN_TO:=0;
        end;
        
       for i:=DOWN_FROM downto DOWN_TO do begin
           if Table[i]='.' then ENDOFMAIL:=i-1;
           if Table[i]='QUIT' then RECEIVE_QUIT:=true;
       end;
       MESSAGE_BODY:=MESSAGE_BODY+receive;

   if ENDOFMAIL>0 then begin
       RECEIVE_DATA:=false;
       exit(protocole_prepare_mail());
   end;

   EXCEPT
        logs.ERRORS('artica-filter:: ParseMultipleDatas: FATAL ERROR WHILE PARSING [' + MESSAGE_IDA + '] CONTENT');
        logs.ERRORS('artica-filter:: ParseMultipleDatas: receive+ "' + receive + '"');

   end;
   
   LOGS.free;
   
    
end;
//##############################################################################
function Tprotocol.protocole_prepare_mail():string;
         const
            CR = #$0d;
            LF = #$0a;
            CRLF = CR + LF;
var
  MyLog,maintenant_day:string;
  logs:Tlogs;
  i:integer;
  maintenant : Tsystemtime;
  SubQueue:string;
  FullQueuePath:string;
  MaxQueueNumber:string;
  myFile : TextFile;
  tpos:integer;
begin

     logs:=Tlogs.Create;
      getlocaltime(maintenant);
      maintenant_day:=logs.FormatHeure(maintenant.Year)+logs.FormatHeure(maintenant.Month)+ logs.FormatHeure(maintenant.Day)+logs.FormatHeure(maintenant.Hour)+logs.FormatHeure(maintenant.minute)+ logs.FormatHeure(maintenant.second)+IntTOStr(Maintenant.MilliSecond);
      MESSAGE_IDA:=maintenant_day+MD5FromString(LIST.Text + maintenant_day);

      SubQueue:='0';
      for i:=0 to 99 do begin
          if CountFiles(QUEUE_PATH + '/' + IntToStr(i))<100 then begin
               SubQueue:=IntToStr(i);
               break;
          end;
      end;
    FullQueuePath:=QUEUE_PATH + '/' + SubQueue;

     ForceDirectories(FullQueuePath);
     if not FileExists(FullQueuePath + '/' + MESSAGE_IDA + '.queue') then begin
        logs.logs('artica-filter:: protocole_prepare_mail:Save to queue ' + FullQueuePath+ '/' + MESSAGE_IDA + '.queue');
        tpos:=pos('.'+CRLF+'QUIT',MESSAGE_BODY);
        if tpos>0 then begin
           MESSAGE_BODY:=LeftStr(MESSAGE_BODY,tpos-1);
        end else begin
            tpos:=pos('.'+CRLF,MESSAGE_BODY);
            if tpos>0 then MESSAGE_BODY:=LeftStr(MESSAGE_BODY,tpos-1);
        end;

        
        AssignFile(myFile, FullQueuePath + '/' + MESSAGE_IDA + '.queue');
        ReWrite(myFile);
        WriteLn(myFile, MESSAGE_BODY);
        CloseFile(myFile);

        
        
        //LIST.SaveToFile(FullQueuePath+ '/' + MESSAGE_IDA + '.queue');
        logs.free;


        LIST.Clear;
        
        for i:=0 to MAILTO_LIST.Count-1 do begin
           logs.logs('artica-filter:: protocole_prepare_mail:[MAIL_TO]="' + MAILTO_LIST.Strings[i] + '"');
           HEAD.Add('MAIL_TO=' + MAILTO_LIST.Strings[i]);
        end;
        

        HEAD.SaveToFile(FullQueuePath + '/' + MESSAGE_IDA + '.head');
        logs.logs('artica-filter:: protocole_prepare_mail:Save to queue ' + FullQueuePath + '/' + MESSAGE_IDA + '.head');
        exit('250 2.0.0 Ok: queued as ' + MESSAGE_IDA + CRLF);
        
        
        
     end else begin
       Logs.logs('artica-filter:: protocole_prepare_mail:[' + MESSAGE_IDA + ']:: WARNING MAIL ALREADY EXISTS !!!!');
       LIST.Clear;
       logs.free;
       exit('250 2.0.0 Ok: queued as ' + MESSAGE_IDA + CRLF);
     
     end;
end;
//##############################################################################
function Tprotocol.ParseProtocol(receive:string):string;
         const
            CR = #$0d;
            LF = #$0a;
            CRLF = CR + LF;
      var
        RegExpr:TRegExpr;
        response:string;
        LOGS:Tlogs;

        Table:TStringDynArray;
        i:integer;
BEGIN
     LOGS:=Tlogs.create;
     LIST:=TStringList.Create;
     RegExpr:=TRegExpr.Create;
     
     RegExpr.Expression:='^RSET';
     if RegExpr.Exec(receive) then begin
       response:='250 2.0.0 Ok' + CRLF;
       exit(response)
     end;

     RegExpr.Expression:='^QUIT';
     if RegExpr.Exec(receive) then begin
       RECEIVE_QUIT:=True;
       exit()
     end;
     RegExpr.Expression:='(helo|HELO)\s+(.+)';
     if RegExpr.Exec(receive) then begin
        exit('250 localhost.localdomain'+CRLF);
     end;

     
     
     RegExpr.Expression:='EHLO\s+(.+)';
     if RegExpr.Exec(receive) then begin
            LOGS.logs('ParseProtocol:: EHLO from ' + RegExpr.Match[1]);
            response:=response+'250-localhost.localdomain'+ CRLF;
            response:=response+'250-PIPELINING'+ CRLF;
            response:=response+'250-SIZE 10240000'+ CRLF;
            response:=response+'250-VRFY'+ CRLF;
            response:=response+'250-ETRN'+ CRLF;
            response:=response+'250-ENHANCEDSTATUSCODES'+ CRLF;
            response:=response+'250-8BITMIME'+ CRLF;
            response:=response+'250 DSN'+ CRLF;
            exit(response);
     
     end;
     
     TRY
     Table:=Explode(CRLF,receive);
     if length(Table)>0 then begin
          LOGS.logs('ParseProtocol:: TABLE= ' + IntToStr(length(TABLE)) + ' entrie(s)');
          for i:=0 to length(Table)-1 do begin
           TRY
               response:=response+ParseProtocolTable(Table[i]);
           EXCEPT
              LOGS.ERRORS('artica-filter:: ParseProtocol:: FATAL ERROR 1252 PARSING MAIL -> ParseProtocolTable');
           end;
          
          end;
     end else begin
          response:=response + ParseProtocolTable(receive);
     end;
     EXCEPT
     
     LOGS.ERRORS('artica-filter:: ParseProtocol:: FATAL ERROR 1247,1257 PARSING MAIL');
     end;


   exit(response);
END;
//####################################################################################
function Tprotocol.ParseProtocolTable(receive:String):string;
         const
            CR = #$0d;
            LF = #$0a;
            CRLF = CR + LF;

var
        RegExpr:TRegExpr;
        response:string;
        LOGS:Tlogs;
        sto:string;
        i:integer;
        Table:TStringDynArray;
begin


    LOGS:=Tlogs.create;
    RegExpr:=TRegExpr.Create;
    //LOGS.logs('ParseProtocolTable::receive:[' + MESSAGE_IDA + ']' + receive);
    Table:=Explode(CRLF,receive);
    if length(Table)>0 then begin
       for i:=0 to length(Table)-1 do begin
           response:=response +  MyProtocol(receive);
       end;
    end else begin
         response:=MyProtocol(receive);
    
    end;
    
    exit(response);
end;
//####################################################################################
function Tprotocol.MyProtocol(receive:String):string;
         const
            CR = #$0d;
            LF = #$0a;
            CRLF = CR + LF;

var
        RegExpr:TRegExpr;
        response:string;
        LOGS:Tlogs;
        sto:string;
        i:integer;
        TempDatas:string;
        logsMailto:string;
        Table:TStringDynArray;

begin
    LOGS:=Tlogs.create;
    LOGS.logs('artica-filter:: ParseProtocolTable::"' + receive + '"');
    RegExpr:=TRegExpr.Create;
    
    
    
    RegExpr.Expression:='(MAIL FROM|mail from):<>\s+SIZE=([0-9]+)';
    if RegExpr.Exec(receive) then begin
        LOGS.logs('artica-filter:: ParseProtocolTable:: sender=is null');
        MAIL_SIZE:=RegExpr.Match[1];
        HEAD.Add('MAIL_FROM=');
        exit('250 2.1.0 Ok' + CRLF);
    end;
    
    
    
    
    
    
    
    RegExpr.Expression:='(MAIL FROM|mail from):<(.+)>';
    if RegExpr.Exec(receive) then begin
          LOGS.logs('artica-filter:: ParseProtocolTable:: sender="' + RegExpr.Match[2] + '"');
          TempDatas:=trim(RegExpr.Match[2]);
          RegExpr.Expression:='SIZE=([0-9]+)';
          if RegExpr.Exec(TempDatas) then MAIL_SIZE:=RegExpr.Match[1];
          RegExpr.Expression:='([a-zA-Z0-9@\-\_\.\?]+)';
          if RegExpr.Exec(TempDatas) then begin
              MAIL_FROM:=RegExpr.Match[1];
              if MAIL_FROM='SIZE' then MAIL_FROM:='root@localhost';
              HEAD.Add('MAIL_FROM='+MAIL_FROM);
              exit('250 2.1.0 Ok' + CRLF);
          end;
          exit('550 bad format' + CRLF);
    end;



    RegExpr.Expression:='(RCPT TO|rcpt to):(.+)';
    if RegExpr.Exec(receive) then begin
          TempDatas:=trim(RegExpr.Match[2]);
             logs.logs('artica-filter: RCPT TO:'+ TempDatas);
             RegExpr.Expression:='([a-zA-Z0-9@\-\_\.\?]+)';
          
          if RegExpr.Exec(TempDatas) then begin
             VerifyDupMailTo(RegExpr.Match[1]);
             RegExpr.Expression:='ORCPT=([a-zA-Z0-9]+);(.+)';
             exit('250 2.1.5 Ok'+CRLF);
          end;
         exit('550 bad format' + CRLF);
    end;
           RegExpr.Expression:='BODY=([A-Za-z0-9]+)';
           if RegExpr.Exec(receive) then BODY_TYPE:=RegExpr.Match[1];

     RegExpr.Expression:='^DATA';
      if RegExpr.Exec(receive) then begin
          for i:=0 to MAILTO_LIST.Count-1 do begin
              logsMailto:=logsMailto + '<' + MAILTO_LIST.Strings[i] + '> ';
          end;
          LOGS.logs('artica-filter:: ParseProtocolTable::[' + MESSAGE_IDA + '] OK accept DATA from=<' + MAIL_FROM+'>, to=' + logsMailto + ', size=' + MAIL_SIZE + ', BODY_TYPE=' + BODY_TYPE + ', ' );
          RECEIVE_DATA:=True;
          response:='354 End data with <CR><LF>.<CR><LF>' + CRLF;
     end;
      exit(response);

end;
//####################################################################################
function Tprotocol.Explode(const Separator, S: string; Limit: Integer = 0):TStringDynArray;
var
  SepLen       : Integer;
  F, P         : PChar;
  ALen, Index  : Integer;
begin
  SetLength(Result, 0);
  if (S = '') or (Limit < 0) then
    Exit;
  if Separator = '' then
  begin
    SetLength(Result, 1);
    Result[0] := S;
    Exit;
  end;
  SepLen := Length(Separator);
  ALen := Limit;
  SetLength(Result, ALen);

  Index := 0;
  P := PChar(S);
  while P^ <> #0 do
  begin
    F := P;
    P := StrPos(P, PChar(Separator));
    if (P = nil) or ((Limit > 0) and (Index = Limit - 1)) then
      P := StrEnd(F);
    if Index >= ALen then
    begin
      Inc(ALen, 5); // mehrere auf einmal um schneller arbeiten zu können
      SetLength(Result, ALen);
    end;
    SetString(Result[Index], F, P - F);
    Inc(Index);
    if P^ <> #0 then
      Inc(P, SepLen);
  end;
  if Index < ALen then
    SetLength(Result, Index); // wirkliche Länge festlegen
end;
//####################################################################################
function Tprotocol.MD5FromString(values:string):string;
var StACrypt,StCrypt:String;
Digest:TMD5Digest;
begin
Digest:=MD5String(values);
exit(MD5Print(Digest));
end;
//##############################################################################
function Tprotocol.get_ARTICA_PHP_PATH():string;
var path:string;
begin
  if not DirectoryExists('/usr/share/artica-postfix') then begin
  path:=ParamStr(0);
  path:=ExtractFilePath(path);
  path:=AnsiReplaceText(path,'/bin/','');
  exit(path);
  end else begin
  exit('/usr/share/artica-postfix');
  end;

end;
//####################################################################################
procedure Tprotocol.VerifyDupMailTo(email_to:string);

var i:integer;
begin
    For i:=0 to MAILTO_LIST.Count-1 do begin
         if MAILTO_LIST.Strings[i]=email_to then exit;

    end;

   MAILTO_LIST.Add(email_to);

end;
//####################################################################################
function Tprotocol.CountFiles(QueuePath:string):integer;
Var Info : TSearchRec;
    Count : Longint;
    D:boolean;
Begin

  Count:=0;
  If FindFirst (QueuePath+'/*.queue',faAnyFile,Info)=0 then begin
    Repeat
      if Info.Name<>'..' then begin
         if Info.Name <>'.' then begin
           inc(Count);

         end;
      end;

    Until FindNext(info)<>0;
    end;
  FindClose(Info);
  exit(Count);
end;
end.

