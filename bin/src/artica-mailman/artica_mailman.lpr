program artica_mailman;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Classes,ldap
  { add your units here }, mailman;
  
  
 var m_mailman:Tmailman;

begin

m_mailman:=Tmailman.Create();

       if ParamStr(1)='-replicate' then begin
           m_mailman.replicate_local_lists();
           halt(0);
       end;
       
       if ParamStr(1)='-single' then begin
           m_mailman.SaveList(ParamStr(2));
           halt(0);
       end;
       
       if ParamStr(1)='-exists' then begin
           if m_mailman.LocalListExists(ParamStr(2)) then begin
              writeln('TRUE');
           end else begin
               writeln('FALSE');
           end;
          halt(0);
       end;
       
       if ParamStr(1)='-Lexists' then begin
              m_mailman.LDAP_LIST_INFOS(ParamStr(2));
              halt(0);
       end;
       
       if ParamStr(1)='-gen' then begin
              m_mailman.SaveGeneralConf();
              writeln('Done...');
              halt(0);
       end;
       
       if ParamStr(1)='-css-patch' then begin
              m_mailman.PatchCss();
              writeln('Done...');
              halt(0);
       end;

writeln('artica-mailman usage :');
writeln('-replicate.............................: replicate local mailman lists to ldap');
writeln('-exists [list].........................: Check if [list] exists on disk');
writeln('-Lexists [list]........................: Check if [list] exists on ldap');
writeln('-single [list].........................: Save ldap settings to mailman list');
writeln('-gen...................................: Maintenance config and apply general settings');
writeln('-css-patch.............................: Patch mailman in order to include css file');


halt(0);

end.

