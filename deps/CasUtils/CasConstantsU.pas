unit CasConstantsU;

interface

uses
  Winapi.Windows,
  Winapi.Messages;

const

  //Messages:
  CM_ASIO             = WM_User + 100;
  CM_UpdateSamplePos  = CM_ASIO + 1;

  //Constants:
  AM_ResetRequest         = 0;
  AM_BufferSwitch         = 1;
  AM_BufferSwitchTimeInfo = 2;
  AM_LatencyChanged       = 3;

  c_nBitDepth       = 24;
  c_nChannelCount   = 2;
  c_nByteSize       = 8;
  c_nBytesInChannel = 3;
  c_nBytesInSample  = 6;

implementation

end.
