unit FuncLib;
//{$DEFINE SMALL} //��С���
interface

uses
  windows, sysutils, Messages, ShellAPI{$IFNDEF SMALL}, ActiveX, ComObj{$ENDIF} {, shlobj};

type
  TStrArr = array of string;

procedure OutDebug(s: string);          //�������

function StrDec(const Str: string): string; //�ַ����ܺ���
function GetFileVersion(FileName: string): Word;
function GetModulePath(hinst: Cardinal; DllName: PChar): PChar; //���DLL����Ŀ¼
procedure MousePosClick(x, y: Integer); //�����ָ������

function RandStr(minLen, maxLen: WORD): string; //����ַ�
function GetSubStr(const _Str, _Start, _End: string): string;
function GetSubStrEx(const _Str, _Start, _End: string; var _LastStr: string {���²���}): string;
function SplitStrArr(const Separators, sContent: string; var StrArr: TStrArr): Integer;

function MyPos(c: Char; const Str: string): Integer; //�Զ���� Pos ���� �ٶ�����5��
function SetPrivilege(const Privilege: PChar): boolean; //SeShutdownPrivilege �ػ�Ȩ��  SeDebugPrivilege ����Ȩ��
function RegDelValue(const Key, Vname: PChar): boolean; //ɾ��ע���ֵ
function RegReadStr(const Key, Vname: PChar): string; //��ע��� str
function RegReadInt(const Key, Vname: PChar): DWORD; //��ע���Integer
function RegWriteStr(const Key, Vname, Value: PChar): boolean; //дSTR
function RegWriteInt(const Key, Vname: PChar; const Value: Integer): boolean; //дDWORD
function GetLocalDrive: string;

function CopyFileAndDir(const source, dest: string): boolean; //�����ļ���Ŀ¼
function DelFileAndDir(const source: string): boolean; //ɾ���ļ���Ŀ¼

function WaitForExec(const CommLine: string; const Time, cmdShow: Cardinal): Cardinal; //�������̲��ȴ�����PID
function SelectDesktop(pName: PChar): boolean; stdcall; //ѡ������
function InputDesktopSelected: boolean; stdcall; //�Ƿ�Ϊ��ǰ����

function JavaScriptEscape(const s: string): string; //JAVASCRIPTת���ַ�
{$IFNDEF SMALL}
function RunJavaScript(const JsCode, JsVar: string): string; //  ���� JsCode ��Ҫִ�е� Js ����; ���� JsVar ��Ҫ���صı���
{$ENDIF}

function GetTickCountUSec(): DWORD;     //΢���ʱ����1/1000 000��
function DiffTickCount(tOld, tNew: DWORD): DWORD; //����ʱ���
implementation

procedure OutDebug(s: string);
begin
  OutputDebugString(PChar(s));
end;


function StrDec(const Str: string): string; //�ַ����ܺ���
const
  XorKey            : array[0..7] of Byte = ($B2, $09, $AA, $55, $93, $6D, $84, $47); //�ַ���������
var
  i, j              : Integer;
begin
  Result := '';
  j := 0;
  try
    for i := 1 to Length(Str) div 2 do begin
      Result := Result + Char(StrToInt('$' + Copy(Str, i * 2 - 1, 2)) xor XorKey[j]);
      j := (j + 1) mod 8;
    end;
  except
  end;
end;

function GetFileVersion(FileName: string): Word;
type
  PVerInfo = ^TVS_FIXEDFILEINFO;
  TVS_FIXEDFILEINFO = record
    dwSignature: longint;
    dwStrucVersion: longint;
    dwFileVersionMS: longint;
    dwFileVersionLS: longint;
    dwFileFlagsMask: longint;
    dwFileFlags: longint;
    dwFileOS: longint;
    dwFileType: longint;
    dwFileSubtype: longint;
    dwFileDateMS: longint;
    dwFileDateLS: longint;
  end;
var
  ExeNames          : array[0..255] of char;
  VerInfo           : PVerInfo;
  Buf               : pointer;
  Sz                : word;
  L, Len            : Cardinal;
begin
  Result := 0;
  StrPCopy(ExeNames, FileName);
  Sz := GetFileVersionInfoSize(ExeNames, L);
  if Sz = 0 then
    Exit;

  try
    GetMem(Buf, Sz);
    try
      GetFileVersionInfo(ExeNames, 0, Sz, Buf);
      if VerQueryValue(Buf, '\', Pointer(VerInfo), Len) then
      begin
        {Result := IntToStr(HIWORD(VerInfo.dwFileVersionMS)) + '.' +
          IntToStr(LOWORD(VerInfo.dwFileVersionMS)) + '.' +
          IntToStr(HIWORD(VerInfo.dwFileVersionLS)) + '.' +
          IntToStr(LOWORD(VerInfo.dwFileVersionLS));   }
        Result := HIWORD(VerInfo.dwFileVersionMS);
      end;
    finally
      FreeMem(Buf);
    end;
  except
    Result := 0;
  end;
end;


{-------------------------------------------------------------------------------
  ������:    GetModulePath
  ����:      HouSoft
  ����:      2009.12.01
  ����:      ģ��ʵ��  ģ���� (ģ��ʵ��Ϊ0ʱģ��������Ч)
  ����ֵ:    PChar
-------------------------------------------------------------------------------}

function GetModulePath(hinst: Cardinal; DllName: PChar): PChar;
var
  i, n              : Integer;
  szFilePath        : array[0..MAX_PATH] of char;
begin
  if hInst > 0 then
    GetModuleFileName(hInst, szFilePath, MAX_PATH)
  else
    GetModuleFileName(GetModuleHandle(DllName), szFilePath, MAX_PATH);
  n := 0;
  for i := Low(szFilePath) to High(szFilePath) do
    case szFilePath[I] of
      '\': n := i;
      #0: Break;
    end;
  szFilePath[n + 1] := #0;
  Result := szFilePath;                 //�˴���,����DLL�����в������
end;


procedure MousePosClick(x, y: Integer);
var
  lpPoint           : TPoint;
begin
  GetCursorPos(lpPoint);
  SetCursorPos(x, y);
  mouse_event(MOUSEEVENTF_LEFTDOWN, 0, 0, 0, 0);
  mouse_event(MOUSEEVENTF_LEFTUP, 0, 0, 0, 0);
  SetCursorPos(lpPoint.X, lpPoint.Y);
end;

function RandStr(minLen, maxLen: WORD): string;
const
  USER_CHARS        = 'abcdefghijklmnopurstuvwxyz1234567890';
var
  i                 : Integer;
  sRet              : string;
  randLen           : integer;
  randChar          : Char;
begin
  sRet := '';
  randLen := minLen + (GetTickCount() + 1) mod (maxLen - minLen); //�������
  SetLength(sRet, randLen);
  for i := 1 to randLen do
  begin
    randChar := USER_CHARS[(Random(GetTickCount) + 1) mod (Length(USER_CHARS) - 1)]; //����ַ�
    if ((i = 1) and (randChar in ['0'..'9'])) or
      (i = randLen) then                //��ͷ����Ϊ����
      randChar := Char(Ord('a') + (GetTickCount() + 1) mod 25);
    sRet[i] := randChar;
  end;
  Result := sRet;
end;

function GetSubStr(const _Str, _Start, _End: string): string;
//20100306
var
  Index             : Integer;
begin
  if _Start <> '' then
  begin
    Index := Pos(_Start, _Str);
    if Index = 0 then
    begin
      Result := '';
      Exit;
    end;
  end else
    Index := 1;

  Result := Copy(_Str, Index + Length(_Start), MaxInt);
  if _End = '' then
    Index := Length(Result) + 1
  else
    Index := Pos(_End, Result);

  Result := Copy(Result, 1, Index - 1);
end;

function GetSubStrEx(const _Str, _Start, _End: string; var _LastStr: string {���²���}): string;
//20100306 Pos �� StrPos �� 1.5��
var
  Index             : Integer;
begin
  if _Start <> '' then
  begin
    Index := Pos(_Start, _Str);
    if Index = 0 then
    begin
      Result := '';
      _LastStr := _Str;
      Exit;
    end;
  end else
    Index := 1;

  _LastStr := Copy(_Str, Index + Length(_Start), MaxInt);
  if _End = '' then
    Index := Length(_Str) + 1
  else
    Index := Pos(_End, _LastStr);

  Result := Copy(_LastStr, 1, Index - 1);
  _LastStr := Copy(_LastStr, Index + Length(_End), MaxInt);
end;


function SplitStrArr(const Separators, sContent: string; var StrArr: TStrArr): Integer;
var
  sStr, sTmp        : string;
begin
  Result := 0;
  SetLength(StrArr, Result);
  sStr := sContent + Separators;
  repeat
    sTmp := GetSubStrEx(sStr, '', Separators, sStr);
    if sTmp <> '' then
    begin
      Inc(Result);
      SetLength(StrArr, Result);
      StrArr[High(StrArr)] := sTmp;
    end;
  until sTmp = '';
end;

//�Զ���� Pos ���� �����ַ����ұ�Pos��10����

function MyPos(c: Char; const Str: string): Integer;
var
  i                 : Integer;
begin
  Result := 0;
  for i := 1 to Length(Str) do
    if c = Str[i] then begin
      Result := i;
      exit
    end;
end;

function SetPrivilege(const Privilege: PChar): boolean; //Ȩ��
var
  OldTokenPrivileges, TokenPrivileges: TTokenPrivileges;
  ReturnLength      : DWORD;
  hToken            : THandle;
  luid              : Int64;
begin
  OpenProcessToken(GetCurrentProcess, TOKEN_ADJUST_PRIVILEGES, hToken);
  LookupPrivilegeValue(nil, Privilege, luid);
  TokenPrivileges.Privileges[0].luid := luid;
  TokenPrivileges.PrivilegeCount := 1;
  TokenPrivileges.Privileges[0].Attributes := 0;
  AdjustTokenPrivileges(hToken, false, TokenPrivileges, sizeof(TTokenPrivileges), OldTokenPrivileges, ReturnLength);
  OldTokenPrivileges.Privileges[0].luid := luid;
  OldTokenPrivileges.PrivilegeCount := 1;
  OldTokenPrivileges.Privileges[0].Attributes := TokenPrivileges.Privileges[0].Attributes or SE_PRIVILEGE_ENABLED;
  Result := AdjustTokenPrivileges(hToken, false, OldTokenPrivileges, ReturnLength, PTokenPrivileges(nil)^, ReturnLength);
end;
{----------end-------------}

function RegDelValue(const Key, Vname: PChar): boolean; //ɾ��ע���ֵ
var
  hk                : HKEY;
begin
  Result := false;
  if RegOpenKey(HKEY_LOCAL_MACHINE, Key, hk) = ERROR_SUCCESS then
    if RegDeleteValue(hk, Vname) = ERROR_SUCCESS then Result := True;
  RegCloseKey(hk);
end;

function RegReadStr(const Key, Vname: PChar): string; //��ע��� str
var
  hk                : HKEY;
  dwSize            : DWORD;
  S                 : array[0..255] of Char;
begin
  Result := '';
  dwSize := 256;
  if RegOpenKey(HKEY_LOCAL_MACHINE, Key, hk) = 0 then
    if RegQueryValueEx(hk, Vname, nil, nil, @S, @dwSize) = 0 then Result := S;
  RegCloseKey(hk);
end;

function RegReadInt(const Key, Vname: PChar): DWORD; //��ע���Integer
var
  hk                : HKEY;
  dwSize, S         : DWORD;
begin
  Result := 3;
  dwSize := 256;
  if RegOpenKey(HKEY_LOCAL_MACHINE, Key, hk) = 0 then
    if RegQueryValueEx(hk, Vname, nil, nil, @S, @dwSize) = 0 then Result := S;
  RegCloseKey(hk);
end;

function RegWriteStr(const Key, Vname, Value: PChar): boolean; //дSTR
var
  hk                : HKEY;
  D                 : DWORD;
begin
  Result := false;
  D := REG_CREATED_NEW_KEY;
  if RegCreateKeyEx(HKEY_LOCAL_MACHINE, Key, 0, nil, 0, KEY_ALL_ACCESS, nil, hk, @D) = 0 then
    if RegSetValueEx(hk, Vname, 0, REG_SZ, Value, Length(Value)) = 0 then Result := True;
  RegCloseKey(hk);
end;

function RegWriteInt(const Key, Vname: PChar; const Value: Integer): boolean; //дDWORD
var
  hk                : HKEY;
  D                 : DWORD;
begin
  Result := false;
  D := REG_CREATED_NEW_KEY;
  if RegCreateKeyEx(HKEY_LOCAL_MACHINE, Key, 0, nil, 0, KEY_ALL_ACCESS, nil, hk, @D) = 0 then
    if RegSetValueEx(hk, Vname, 0, REG_DWORD, @Value, sizeof(Value)) = 0 then Result := True;
  RegCloseKey(hk);
end;

function GetLocalDrive(): string;
var
  c                 : Char;
  S                 : string;
const
  GByte             = 1073741824;
begin
  for c := 'C' to 'Z' do                {C-Z}
    if GETDRIVETYPE(PChar(c + ':\')) in [2..3] then begin
      S := S + c + Format('��(%.2f/', [DISKFREE(Ord(c) - 64) / GByte]) + Format('%.2fG) ', [DiskSize(Ord(c) - 64) / GByte]);
    end;
  Result := S;
end;

function CopyFileAndDir(const source, dest: string): boolean;
var
  fo                : TSHFILEOPSTRUCT;
begin
  FillChar(fo, sizeof(fo), 0);
  with fo do begin
    Wnd := 0;
    wFunc := FO_Copy;
    pFrom := PChar(source + #0);
    pTo := PChar(dest + #0);
    fFlags := FOF_NOCONFIRMATION or FOF_NOERRORUI or FOF_SILENT;
  end;
  Result := (SHFileOperation(fo) = 0);
end;

function DelFileAndDir(const source: string): boolean;
var
  fo                : TSHFILEOPSTRUCT;
begin
  FillChar(fo, sizeof(fo), 0);
  with fo do begin
    Wnd := 0;
    wFunc := FO_DELETE;
    pFrom := PChar(source + #0);
    pTo := #0#0;
    fFlags := FOF_NOCONFIRMATION + FOF_SILENT;
  end;
  Result := (SHFileOperation(fo) = 0);
end;


function WaitForExec(const CommLine: string; const Time, cmdShow: Cardinal): Cardinal; //�������̲��ȴ�����PID
var
  si                : STARTUPINFO;
  pi                : PROCESS_INFORMATION;
begin
  ZeroMemory(@si, sizeof(si));
  si.cb := sizeof(si);
  si.dwFlags := STARTF_USESHOWWINDOW;
  si.wShowWindow := cmdShow;
  CreateProcess(nil, PChar(CommLine), nil, nil, false, CREATE_DEFAULT_ERROR_MODE, nil, nil, si, pi);
  WaitForSingleObject(pi.hProcess, Time);
  Result := pi.dwProcessID;
end;

{�����л�}

function SelectHDESK(HNewDesk: HDESK): boolean; stdcall;
var
  HOldDesk          : HDESK;
  dwDummy           : DWORD;
  sName             : array[0..255] of Char;
begin
  Result := false;
  HOldDesk := GetThreadDesktop(GetCurrentThreadId);
  if (not GetUserObjectInformation(HNewDesk, UOI_NAME, @sName[0], 256, dwDummy)) then begin
    //OutputDebugString('GetUserObjectInformation Failed.');
    exit;
  end;
  if (not SetThreadDesktop(HNewDesk)) then begin
    //OutputDebugString('SetThreadDesktop Failed.');
    exit;
  end;
  if (not CloseDesktop(HOldDesk)) then begin
    //OutputDebugString('CloseDesktop Failed.');
    exit;
  end;
  Result := True;
end;

function SelectDesktop(pName: PChar): boolean; stdcall;
var
  HDesktop          : HDESK;
begin
  Result := false;
  if Assigned(pName) then
    HDesktop := OpenDesktop(pName, 0, false,
      DESKTOP_CREATEMENU or DESKTOP_CREATEWINDOW or
      DESKTOP_ENUMERATE or DESKTOP_HOOKCONTROL or
      DESKTOP_WRITEOBJECTS or DESKTOP_READOBJECTS or
      DESKTOP_SWITCHDESKTOP or GENERIC_WRITE)
  else
    HDesktop := OpenInputDesktop(0, false,
      DESKTOP_CREATEMENU or DESKTOP_CREATEWINDOW or
      DESKTOP_ENUMERATE or DESKTOP_HOOKCONTROL or
      DESKTOP_WRITEOBJECTS or DESKTOP_READOBJECTS or
      DESKTOP_SWITCHDESKTOP or GENERIC_WRITE);
  if (HDesktop = 0) then begin
    //OutputDebugString(PChar('Get Desktop Failed: ' + IntToStr(GetLastError)));
    exit;
  end;
  Result := SelectHDESK(HDesktop);
end;

function InputDesktopSelected: boolean; stdcall;
var
  HThdDesk          : HDESK;
  HInpDesk          : HDESK;
  //dwError: DWORD;
  dwDummy           : DWORD;
  sThdName          : array[0..255] of Char;
  sInpName          : array[0..255] of Char;
begin
  Result := false;
  HThdDesk := GetThreadDesktop(GetCurrentThreadId);
  HInpDesk := OpenInputDesktop(0, false,
    DESKTOP_CREATEMENU or DESKTOP_CREATEWINDOW or
    DESKTOP_ENUMERATE or DESKTOP_HOOKCONTROL or
    DESKTOP_WRITEOBJECTS or DESKTOP_READOBJECTS or
    DESKTOP_SWITCHDESKTOP);
  if (HInpDesk = 0) then begin
    //OutputDebugString('OpenInputDesktop Failed.');
    //dwError := GetLastError;
    //result := (dwError = 170);
    exit;
  end;
  if (not GetUserObjectInformation(HThdDesk, UOI_NAME, @sThdName[0], 256, dwDummy)) then begin
    //OutputDebugString('GetUserObjectInformation HThdDesk Failed.');
    CloseDesktop(HInpDesk);
    exit;
  end;
  if (not GetUserObjectInformation(HInpDesk, UOI_NAME, @sInpName[0], 256, dwDummy)) then begin
    //OutputDebugString('GetUserObjectInformation HInpDesk Failed.');
    CloseDesktop(HInpDesk);
    exit;
  end;
  CloseDesktop(HInpDesk);
  Result := (lstrcmp(sThdName, sInpName) = 0);
end;

{procedure ScreenTextOut(Str: PChar);
var
  dm: hDC;
begin
  dm := GetWindowDC(0);
  SetTextColor(dm,$0000FF);
 // SetBkMode(dm, TRANSPARENT);
  TextOut(dm, GetSystemMetrics(SM_CXSCREEN) div 2, GetSystemMetrics(SM_CYSCREEN) div 2, Str, Length(Str));

  end; }


{
ת������ �ַ�
  \b �˸�
  \f ��ֽ��ҳ
  \n ����
  \r �س�
  \t �������� (Ctrl-I)
  \' ������
  \" ˫����
  \\ ��б��
 }

function JavaScriptEscape(const s: string): string;
var
  i                 : Integer;
  sTmp              : string;
begin
  sTmp := '';
  if Length(s) > 0 then
    for i := 1 to Length(s) do
      case s[i] of
        '\': sTmp := sTmp + '\\';
        '"': sTmp := sTmp + '\"';
        '''': sTmp := sTmp + '\''';
        #13: sTmp := sTmp + '\r';
        #12: sTmp := sTmp + '\f';
        #10: sTmp := sTmp + '\n';
        #9: sTmp := sTmp + '\t';
        #8: sTmp := sTmp + '\b';
      else
        sTmp := sTmp + s[i];
      end;
  Result := sTmp;
end;

{$IFNDEF SMALL}
{�˺�����Ҫ ComObj ��Ԫ��֧��}
{���� JsCode ��Ҫִ�е� Js ����; ���� JsVar ��Ҫ���صı���}
{  WinExec('regsvr32 Msscript.ocx', SW_SHOW);}

function RunJavaScript(const JsCode, JsVar: string): string;
var
  script            : OleVariant;
begin
  try
    CoInitialize(nil);
    script := CreateOleObject('ScriptControl'); //CreateOleObject('ScriptControl');
    script.Language := 'JScript';
    script.ExecuteStatement(JsCode);
    Result := script.Eval(JsVar);
    CoUninitialize;
  except
    on E: Exception do begin
      OutDebug('RunJavaScript ' + E.Message);
      Result := '';
    end;
  end;
end;
{$ENDIF}

var
  Frequency         : Int64;

function GetTickCountUSec;              //�� GetTickCount���ȸ�25~30����
var
  lpPerformanceCount: Int64;
begin
  if Frequency = 0 then begin
    QueryPerformanceFrequency(Frequency); //WINDOWS API ���ؼ���Ƶ��(Intel86:1193180)(���ϵͳ�ĸ�����Ƶ�ʼ�������һ���ڵ��𶯴���)
    Frequency := Frequency div 1000000; //һ΢�����񶯴���
  end;
  QueryPerformanceCounter(lpPerformanceCount);
  Result := lpPerformanceCount div Frequency;
end;

function DiffTickCount;                 //����ʱ���
begin
  if tNew >= tOld then Result := tNew - tOld
  else Result := DWORD($FFFFFFFF) - tOld + tNew;
end;
end.