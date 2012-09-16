program ArticaQuarantine;

{$mode objfpc}{$H+}

uses
  Classes, SysUtils
  { add your units here }, ldap, quarantine,reports;



var
   T:Tquarantine;
   R:Treports;
begin
      R:=Treports.Create;
      T:=Tquarantine.Create;
     if ParamStr(1)='-fix' then begin
          T.Fixup();
      halt(0);
     end;
     

    
      if ParamStr(1)='deleteallmailfrommailtoother' then begin
          R.deleteallmailfrommailtoother(ParamStr(2));
          halt(0);
     end;
      if ParamStr(1)='deleteallmailfrommailtoyesterday' then begin
          R.deleteallmailfrommailtoyesterday(ParamStr(2));
          halt(0);
     end;
     
      if ParamStr(1)='-maintenance' then begin
          T.CleanAllQuarantines();
          T.SendAllReports();
          halt(0);
     end;
     
      if ParamStr(1)='-clean-quarantines' then begin
          T.CleanAllQuarantines();
          halt(0);
     end;
     
       if ParamStr(1)='-fix-quarantines' then begin
          T.FixQuarantines();
          halt(0);
     end;


       if ParamStr(1)='-delete-quarantines' then begin
          T.DeleteAllQuarantines();
          halt(0);
     end;


      if ParamStr(1)='-send-reports' then begin
          T.SendAllReports();
          halt(0);
     end;
     

    if ParamStr(1)='-ou' then begin
       if ParamStr(2)='quarantine' then begin
          T.UserListAsQuarantine(ParamStr(3));
          halt(0);
       end;
       
       if ParamStr(2)='config' then begin
          T.OuConfig(ParamStr(3));
          halt(0);
       end;
       
       if ParamStr(2)='MaxDay' then begin
           T.OuDeleteMaxDayQuarantine(ParamStr(3));
           halt(0);
       end;
     end;
     
     


    writeln('ARTICA QUARANTINE');
    writeln('-clean-quarantines......: Clean all Quarantine''s Organizations defined by the max day settings');
    writeln('-fix-quarantines........: Clean all quarantines according emails doesn''t exists in the disk');
    writeln('-delete-quarantines.....: Delete definitively all quarantines');
    writeln('-send-reports...........: Send all quarantine reports to users  (optional: add "debug" at the end) ');
    writeln('-ou config..............: Get config from ou ');
    writeln('-ou quarantine [org]....: Show quarantine status of "organization"');
    writeln('-ou MaxDay [org]........: Simulate quarantine deletion of max day');

end.

