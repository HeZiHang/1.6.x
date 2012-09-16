unit unixnetwork;

{$mode objfpc}{$H+}

interface

uses
//depreciated oldlinux -> baseunix
Classes, SysUtils,variants,strutils, Process,IniFiles,baseunix,unix,md5,RegExpr in 'RegExpr.pas',logs,zsystem,libc;

  type
  tnetwork=class


private
   LOGS:TLogs;
   SYS:Tsystem;
   function TCP_GetFlags(ifname: String): Integer;
public
    constructor Create;
    procedure Free;
    function  LOCAL_IP(ifname:string):string;
    function  isNetworkDown():boolean;
    procedure LocalIPList(var iplist:tstringlist);
end;

implementation

//-------------------------------------------------------------------------------------------------------


//##############################################################################
constructor tnetwork.Create;

begin
       forcedirectories('/etc/artica-postfix');









end;
//##############################################################################
PROCEDURE tnetwork.Free();
begin
logs.free;
SYS.free;

end;
//##############################################################################
function tnetwork.isNetworkDown():boolean;
var
l:TstringList;
begin
result:=true;
l:=Tstringlist.Create;
LocalIPList(l);
if l.Count>0 then begin
    result:=false;
    l.free;
end;

end;
//##############################################################################


function tnetwork.LOCAL_IP(ifname:string):string;
var
 ifr : ifreq;
 sock : longint;
 p:pChar;


begin
 Result:='';

 strncpy( ifr.ifr_ifrn.ifrn_name, pChar(ifname), IF_NAMESIZE-1 );
 ifr.ifr_ifru.ifru_addr.sa_family := AF_INET;
 sock := socket(AF_INET, SOCK_DGRAM, IPPROTO_IP);
 if ( sock >= 0 ) then begin
   if ( ioctl( sock, SIOCGIFADDR, @ifr ) >= 0 ) then begin
     p:=inet_ntoa( ifr.ifr_ifru.ifru_addr.sin_addr );
     if ( p <> nil ) then Result :=  p;
   end;
   libc.__close(sock);
 end;
end;
//##############################################################################
procedure tnetwork.LocalIPList(var iplist:tstringlist);
var
  ifc: ifconf;
  ifr: array[0..1023] of ifreq;
  sock, I: Integer;
  RigaOut: String;
  inetname,ip:string;
begin
  sock:= socket(AF_INET, SOCK_DGRAM, 0);
  if sock>= 0 then begin
    ifc.ifc_len:= SizeOf(ifr);
    ifc.ifc_ifcu.ifcu_req:= ifr;
    if ioctl(sock, SIOCGIFCONF, @ifc)= 0 then begin
      for I:= 0 to ifc.ifc_len div SizeOf(ifreq)- 1 do begin
          inetname:=ifr[I].ifr_ifrn.ifrn_name;
          if (TCP_GetFlags(ifr[I].ifr_ifrn.ifrn_name) and IFF_LOOPBACK)<> 0 then continue;

        if (TCP_GetFlags(ifr[I].ifr_ifrn.ifrn_name) and IFF_UP)<> 0 then begin
             ip:=LOCAL_IP(inetname);
             if length(ip)>0 then iplist.Add(inetname);
        end;

      end;
    end;
    libc.__close(sock);
  end;
end;
//##############################################################################
function tnetwork.TCP_GetFlags(ifname: String): Integer;
var
  ifr : ifreq;
  sock: Integer;
begin
  TCP_GetFlags:= 0;
  strncpy(ifr.ifr_ifrn.ifrn_name, pChar(ifname), IF_NAMESIZE- 1);
  sock:= socket(AF_INET, SOCK_DGRAM, 0);
  if sock>= 0 then begin
    if ioctl(sock, SIOCGIFFLAGS, @ifr)>= 0 then begin
      TCP_GetFlags:= ifr.ifr_ifru.ifru_flags;
    end;
    libc.__close(sock);
  end;
end;
//##############################################################################
end.


