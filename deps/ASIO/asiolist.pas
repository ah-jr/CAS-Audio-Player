unit
    AsioList;

interface

uses
    Classes, ActiveX, AnsiStrings;

type
    TAsioDriverDesc = packed record
      id   : TCLSID;
      name : array[0..511] of AnsiChar;
      path : array[0..511] of AnsiChar;
    end;
    PAsioDriverDesc = ^TAsioDriverDesc;

    TAsioDriverList = array of TAsioDriverDesc;


procedure ListAsioDrivers(var List: TAsioDriverList);


implementation

uses
    Windows, Registry, SysUtils, ComObj;

const
     ASIODRV_DESC  = 'description';
     INPROC_SERVER = 'InprocServer32';
     ASIO_PATH     = 'software\asio';
     COM_CLSID     = 'clsid';


function findDrvPath(const clsidstr: AnsiString; var dllpath: AnsiString): longint;
var
   reg      : TRegistry;
   success  : boolean;
   buf      : array[0..1024] of AnsiChar;
   s        : AnsiString;
   temps    : AnsiString;
   filename : AnsiString;
   handle   : THandle;
begin
  Result := -1;

  reg := TRegistry.Create;
  try
    dllpath := '';
    reg.RootKey := HKEY_CLASSES_ROOT;
    success := reg.OpenKeyReadOnly(String(COM_CLSID + '\' + clsidstr + '\' + INPROC_SERVER));
    if success then
    begin
      filename := '';
      dllpath := AnsiString(reg.ReadString(''));
      filename := AnsiString(ExtractFilename(String(dllpath)));

      if (ExtractFilePath(String(dllpath)) = '') and (String(dllpath) <> '') then
      begin
        buf[0] := #0;
        temps := dllpath;
        if GetSystemDirectoryA(buf, 1023) <> 0 then
        begin
          s := buf;
          dllpath := s + '\' + temps;

          if not FileExists(String(dllpath)) then
          begin
            s := buf + AnsiString('32');
            dllpath := s + '\' + temps;
          end;
        end;

        if not FileExists(String(dllpath)) then
        begin
          buf[0] := #0;
          if GetWindowsDirectoryA(buf, 1023) <> 0 then
          begin
            s := buf;
            dllpath := s + '\' + temps;
          end;
        end;
      end;

      if FileExists(String(dllpath)) then
        Result := 0
      else if (filename <> '') then
      begin
        dllpath := '';
        handle := SafeLoadLibrary(String(Filename));
        if handle <> 0 then
        begin
          FreeLibrary(handle);
          Result := 0;
        end;
      end;
    end;
  finally
    reg.Free;
  end;
end;

procedure ListAsioDrivers(var List: TAsioDriverList);
var
   r       : TRegistry;
   keys    : TStringList;
   success : boolean;
   i       : integer;
   id      : AnsiString;
   dllpath : AnsiString;
   count   : integer;
   res     : integer;
begin
  SetLength(List, 0);

  keys := TStringList.Create;
  r := TRegistry.Create;
  try
    r.RootKey := HKEY_LOCAL_MACHINE;
    success := r.OpenKeyReadOnly(ASIO_PATH);
    if success then
    begin
      r.GetKeyNames(keys);
      r.CloseKey;
    end;

    count := 0;
    for i := 0 to keys.Count-1 do
    begin
      success := r.OpenKeyReadOnly(ASIO_PATH + '\' + keys[i]);
      if success then
      begin
        id := AnsiString(r.ReadString(COM_CLSID));
        dllpath := '';
        res := findDrvPath(id, dllpath);
        if res = 0 then
        begin
          SetLength(List, count+1);
          try
            List[count].id := StringToGUID(String(id));
            AnsiStrings.StrPLCopy(List[count].name, AnsiString(keys[i]), 512);
            AnsiStrings.StrPLCopy(List[count].path, dllpath, 512);
            inc(count);
          except on EConvertError do
          end;
        end;
        r.CloseKey;
      end;
    end;

    SetLength(List, count);
  finally
    keys.Free;
    r.Free;
  end;
end;

end.
