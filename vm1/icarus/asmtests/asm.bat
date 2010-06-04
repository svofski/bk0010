set XASM=s:\pdpxasm\pasm
set XLNK=s:\pdpxasm\plink

%XASM% /L %1
%XLNK% %1

