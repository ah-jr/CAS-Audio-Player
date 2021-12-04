(*******************************************************************************

	Steinberg Audio Stream I/O API
	(c) 1997 - 2005, Steinberg Media Technologies GmbH

	ASIO Interface Specification v 2.1

	2005 - Added support for DSD sample data (in cooperation with Sony)

	basic concept is an i/o synchronous double-buffer scheme:

	on bufferSwitch(index == 0), host will read/write:

		after ASIOStart(), the
  read  first input buffer A (index 0)
	|   will be invalid (empty)
	*   ------------------------
	|------------------------|-----------------------|
	|                        |                       |
	|  Input Buffer A (0)    |   Input Buffer B (1)  |
	|                        |                       |
	|------------------------|-----------------------|
	|                        |                       |
	|  Output Buffer A (0)   |   Output Buffer B (1) |
	|                        |                       |
	|------------------------|-----------------------|
	*                        -------------------------
	|                        before calling ASIOStart(),
  write                      host will have filled output
                             buffer B (index 1) already

  *please* take special care of proper statement of input
  and output latencies (see ASIOGetLatencies()), these
  control sequencer sync accuracy

--------------------------------------------------------------------------------

  Delphi translation by Frederic Vanmol (frederic@axiworld.be)

  Thanks to
  - Martin Fay for OpenAsio.dll
  - Florent Ouchet for the asm code that makes OpenAsio.dll unnecessary
          (http://www.delphigroups.info/2/2/1024225.html)

  Changes
  -------
  (2011/10/14)
  - added IASIO and TOpenASIO definitions
  - no more need for OpenASIO dll
  - 64bit support

*******************************************************************************)
unit
    Asio;

interface

uses
    Windows, ActiveX;

// force 4 byte alignment

//- - - - - - - - - - - - - - - - - - - - - - - - -
// Type definitions
//- - - - - - - - - - - - - - - - - - - - - - - - -

type
    // use the function ASIOSamplesToInt64 to convert to an Int64
    TASIOInt64 = record
      hi : dword;
      lo : dword;
    end;

function ASIOSamplesToInt64(const samples: TASIOInt64): Int64;
function Int64ToASIOSamples(const value: Int64): TASIOInt64;


type
    TASIOSamples = TASIOInt64;

    // Timestamp data type is 64 bit integer,
    // Time format is Nanoseconds.
    TASIOTimeStamp = TASIOInt64;


    // Samplerates are expressed in IEEE 754 64 bit double float,
    // native format as host computer
    TASIOSampleRate = double;


    // Boolean values are expressed as long
    TASIOBool = longint;

const
     ASIOFalse = 0;
     ASIOTrue  = 1;


type
    // Sample Types are expressed as long
    TASIOSampleType = longint;

const
     ASIOSTInt16MSB   = 0;
     ASIOSTInt24MSB   = 1;		// used for 20 bits as well
     ASIOSTInt32MSB   = 2;
     ASIOSTFloat32MSB = 3;		// IEEE 754 32 bit float
     ASIOSTFloat64MSB = 4;		// IEEE 754 64 bit double float

     // these are used for 32 bit data buffer, with different alignment of the data inside
     // 32 bit PCI bus systems can be more easily used with these
     ASIOSTInt32MSB16 = 8;		// 32 bit data with 16 bit alignment
     ASIOSTInt32MSB18 = 9;		// 32 bit data with 18 bit alignment
     ASIOSTInt32MSB20 = 10;		// 32 bit data with 20 bit alignment
     ASIOSTInt32MSB24 = 11;		// 32 bit data with 24 bit alignment

     ASIOSTInt16LSB   = 16;
     ASIOSTInt24LSB   = 17;		// used for 20 bits as well
     ASIOSTInt32LSB   = 18;
     ASIOSTFloat32LSB = 19;		// IEEE 754 32 bit float, as found on Intel x86 architecture
     ASIOSTFloat64LSB = 20; 		// IEEE 754 64 bit double float, as found on Intel x86 architecture

     // these are used for 32 bit data buffer, with different alignment of the data inside
     // 32 bit PCI bus systems can more easily used with these
     ASIOSTInt32LSB16 = 24;		// 32 bit data with 16 bit alignment
     ASIOSTInt32LSB18 = 25;		// 32 bit data with 18 bit alignment
     ASIOSTInt32LSB20 = 26;		// 32 bit data with 20 bit alignment
     ASIOSTInt32LSB24 = 27;             // 32 bit data with 24 bit alignment

     //	ASIO DSD format.
     ASIOSTDSDInt8LSB1 = 32;		// DSD 1 bit data, 8 samples per byte. First sample in Least significant bit.
     ASIOSTDSDInt8MSB1 = 33;		// DSD 1 bit data, 8 samples per byte. First sample in Most significant bit.
     ASIOSTDSDInt8NER8 = 40;		// DSD 8 bit data, 1 sample per byte. No Endianness required.



(*-----------------------------------------------------------------------------

// DSD operation and buffer layout

// Definition by Steinberg/Sony Oxford.

//

// We have tried to treat DSD as PCM and so keep a consistant structure across

// the ASIO interface.

//

// DSD's sample rate is normally referenced as a multiple of 44.1Khz, so

// the standard sample rate is refered to as 64Fs (or 2.8224Mhz). We looked

// at making a special case for DSD and adding a field to the ASIOFuture that

// would allow the user to select the Over Sampleing Rate (OSR) as a seperate

// entity but decided in the end just to treat it as a simple value of

// 2.8224Mhz and use the standard interface to set it.

//

// The second problem was the "word" size, in PCM the word size is always a

// greater than or equal to 8 bits (a byte). This makes life easy as we can

// then pack the samples into the "natural" size for the machine.

// In DSD the "word" size is 1 bit. This is not a major problem and can easily

// be dealt with if we ensure that we always deal with a multiple of 8 samples.

//

// DSD brings with it another twist to the Endianness religion. How are the

// samples packed into the byte. It would be nice to just say the most significant

// bit is always the first sample, however there would then be a performance hit

// on little endian machines. Looking at how some of the processing goes...

// Little endian machines like the first sample to be in the Least Significant Bit,

//   this is because when you write it to memory the data is in the correct format

//   to be shifted in and out of the words.

// Big endian machine prefer the first sample to be in the Most Significant Bit,

//   again for the same reasion.

//

// And just when things were looking really muddy there is a proposed extension to

// DSD that uses 8 bit word sizes. It does not care what endianness you use.

//

// Switching the driver between DSD and PCM mode

// ASIOFuture allows for extending the ASIO API quite transparently.

// See kAsioSetIoFormat, kAsioGetIoFormat, kAsioCanDoIoFormat

//

//-----------------------------------------------------------------------------*)




//- - - - - - - - - - - - - - - - - - - - - - - - -
// Error codes
//- - - - - - - - - - - - - - - - - - - - - - - - -

type
    TASIOError = longint;

const
     ASE_OK               = 0;                 // This value will be returned whenever the call succeeded
     ASE_SUCCESS          = $3F4847A0;         // unique success return value for ASIOFuture calls
     ASE_NotPresent       = -1000;             // hardware input or output is not present or available
     ASE_HWMalfunction    = ASE_NotPresent+1;  // hardware is malfunctioning (can be returned by any ASIO function)
     ASE_InvalidParameter = ASE_NotPresent+2;  // input parameter invalid
     ASE_InvalidMode      = ASE_NotPresent+3;  // hardware is in a bad mode or used in a bad mode
     ASE_SPNotAdvancing   = ASE_NotPresent+4;  // hardware is not running when sample position is inquired
     ASE_NoClock          = ASE_NotPresent+5;  // sample clock or rate cannot be determined or is not present
     ASE_NoMemory         = ASE_NotPresent+6;  // not enough memory for completing the request


//---------------------------------------------------------------------------------------------------
//---------------------------------------------------------------------------------------------------

//- - - - - - - - - - - - - - - - - - - - - - - - -
// Time Info support
//- - - - - - - - - - - - - - - - - - - - - - - - -

type
    TASIOTimeCode = packed record
      speed           : double;        // speed relation (fraction of nominal speed)
	                               // optional; set to 0. or 1. if not supported
      timecodeSamples : TASIOSamples;  // time in samples
      flags           : longword;      // some information flags (see below)
      future          : array[0..63] of AnsiChar;
    end;

type
    ASIOTimeCodeFlags = longint;

const
     kTcValid      = 1;
     kTcRunning    = 1 shl 1;
     kTcReverse    = 1 shl 2;
     kTcOnspeed    = 1 shl 3;
     kTcStill      = 1 shl 4;

     kTcSpeedValid = 1 shl 8;


type
    TAsioTimeInfo = packed record
      speed          : double;             // absolute speed (1. = nominal)
      systemTime     : TASIOTimeStamp;     // system time related to samplePosition, in nanoseconds
	                                   // on mac, must be derived from Microseconds() (not UpTime()!)
	                                   // on windows, must be derived from timeGetTime()
      samplePosition : TASIOSamples;
      sampleRate     : TASIOSampleRate;    // current rate
      flags          : longword;           // (see below)
      reserved       : array[0..11] of AnsiChar;
    end;


    TAsioTimeInfoFlags = longint;

const
     kSystemTimeValid     = 1;             // must always be valid
     kSamplePositionValid = 1 shl 1;       // must always be valid
     kSampleRateValid     = 1 shl 2;
     kSpeedValid          = 1 shl 3;

     kSampleRateChanged   = 1 shl 4;
     kClockSourceChanged  = 1 shl 5;


type
    PASIOTime = ^TASIOTime;
    TASIOTime = packed record        // both input/output
      reserved : array[0..3] of longint;  // must be 0
      timeInfo : TASIOTimeInfo;           // required
      timeCode : TASIOTimeCode;           // optional, evaluated if (timeCode.flags & kTcValid)
    end;

(*

using time info:
it is recommended to use the new method with time info even if the asio
device does not support timecode; continuous calls to ASIOGetSamplePosition
and ASIOGetSampleRate are avoided, and there is a more defined relationship
between callback time and the time info.

see the example below.
to initiate time info mode, after you have received the callbacks pointer in
ASIOCreateBuffers, you will call the asioMessage callback with kAsioSupportsTimeInfo
as the argument. if this returns 1, host has accepted time info mode.
now host expects the new callback bufferSwitchTimeInfo to be used instead
of the old bufferSwitch method. the ASIOTime structure is assumed to be valid
and accessible until the callback returns.

using time code:
if the device supports reading time code, it will call host's asioMessage callback
with kAsioSupportsTimeCode as the selector. it may then fill the according
fields and set the kTcValid flag.
host will call the future method with the kAsioEnableTimeCodeRead selector when
it wants to enable or disable tc reading by the device. you should also support
the kAsioCanTimeInfo and kAsioCanTimeCode selectors in ASIOFuture (see example).

note:
the AsioTimeInfo/ASIOTimeCode pair is supposed to work in both directions.
as a matter of convention, the relationship between the sample
position counter and the time code at buffer switch time is
(ignoring offset between tc and sample pos when tc is running):

on input:	sample 0 -> input  buffer sample 0 -> time code 0
on output:	sample 0 -> output buffer sample 0 -> time code 0

this means that for 'real' calculations, one has to take into account
the according latencies.

example:

ASIOTime asioTime;

in createBuffers()
{
	memset(&asioTime, 0, sizeof(ASIOTime));
	AsioTimeInfo* ti = &asioTime.timeInfo;
	ti->sampleRate = theSampleRate;
	ASIOTimeCode* tc = &asioTime.timeCode;
	tc->speed = 1.;
	timeInfoMode = false;
	canTimeCode = false;
	if(callbacks->asioMessage(kAsioSupportsTimeInfo, 0, 0, 0) == 1)
	{
		timeInfoMode = true;
#if kCanTimeCode
		if(callbacks->asioMessage(kAsioSupportsTimeCode, 0, 0, 0) == 1)
			canTimeCode = true;
#endif
	}
}

void switchBuffers(long doubleBufferIndex, bool processNow)
{
	if(timeInfoMode)
	{
		AsioTimeInfo* ti = &asioTime.timeInfo;
		ti->flags =	kSystemTimeValid | kSamplePositionValid | kSampleRateValid;
		ti->systemTime = theNanoSeconds;
		ti->samplePosition = theSamplePosition;
		if(ti->sampleRate != theSampleRate)
			ti->flags |= kSampleRateChanged;
		ti->sampleRate = theSampleRate;

#if kCanTimeCode
		if(canTimeCode && timeCodeEnabled)
		{
			ASIOTimeCode* tc = &asioTime.timeCode;
			tc->timeCodeSamples = tcSamples;						// tc in samples
			tc->flags = kTcValid | kTcRunning | kTcOnspeed;			// if so...
		}
		ASIOTime* bb = callbacks->bufferSwitchTimeInfo(&asioTime, doubleBufferIndex, processNow ? ASIOTrue : ASIOFalse);
#else
		callbacks->bufferSwitchTimeInfo(&asioTime, doubleBufferIndex, processNow ? ASIOTrue : ASIOFalse);
#endif
	}
	else
		callbacks->bufferSwitch(doubleBufferIndex, ASIOFalse);
}

ASIOError ASIOFuture(long selector, void *params)
{
	switch(selector)
	{
		case kAsioEnableTimeCodeRead:
			timeCodeEnabled = true;
			return ASE_SUCCESS;
		case kAsioDisableTimeCodeRead:
			timeCodeEnabled = false;
			return ASE_SUCCESS;
		case kAsioCanTimeInfo:
			return ASE_SUCCESS;
		#if kCanTimeCode
		case kAsioCanTimeCode:
			return ASE_SUCCESS;
		#endif
	}
	return ASE_NotPresent;
};

*)

//- - - - - - - - - - - - - - - - - - - - - - - - -
// application's audio stream handler callbacks
//- - - - - - - - - - - - - - - - - - - - - - - - -

type
    TASIOBufferSwitchProc = procedure(doubleBufferIndex: longint; directProcess: TASIOBool); cdecl;
    TASIOSampleRateDidChangeProc = procedure(sRate: TASIOSampleRate); cdecl;
    TASIOMessageFunc = function(selector, value: longint; message: pointer; opt: pdouble): longint; cdecl;
    TASIOBufferSwitchTimeInfoFunc = function(var params: TASIOTime; doubleBufferIndex: longint; directProcess: TASIOBool): PASIOTime; cdecl;


    TASIOCallbacks = packed record
      bufferSwitch : TASIOBufferSwitchProc;
		// bufferSwitch indicates that both input and output are to be processed.
		// the current buffer half index (0 for A, 1 for B) determines
		// - the output buffer that the host should start to fill. the other buffer
		//   will be passed to output hardware regardless of whether it got filled
		//   in time or not.
		// - the input buffer that is now filled with incoming data. Note that
		//   because of the synchronicity of i/o, the input always has at
		//   least one buffer latency in relation to the output.
		// directProcess suggests to the host whether it should immedeately
		// start processing (directProcess == ASIOTrue), or whether its process
		// should be deferred because the call comes from a very low level
		// (for instance, a high level priority interrupt), and direct processing
		// would cause timing instabilities for the rest of the system. If in doubt,
		// directProcess should be set to ASIOFalse.
		// Note: bufferSwitch may be called at interrupt time for highest efficiency.

      sampleRateDidChange : TASIOSampleRateDidChangeProc;
		// gets called when the AudioStreamIO detects a sample rate change
		// If sample rate is unknown, 0 is passed (for instance, clock loss
		// when externally synchronized).

      asioMessage : TASIOMessageFunc;
		// generic callback for various purposes, see selectors below.
		// note this is only present if the asio version is 2 or higher

      bufferSwitchTimeInfo : TASIOBufferSwitchTimeInfoFunc;
		// new callback with time info. makes ASIOGetSamplePosition() and various
		// calls to ASIOGetSampleRate obsolete,
		// and allows for timecode sync etc. to be preferred; will be used if
		// the driver calls asioMessage with selector kAsioSupportsTimeInfo.
    end;



const
     // asioMessage selectors
     kAsioSelectorSupported    = 1;     // selector in <value>, returns 1L if supported,
                                        //   0 otherwise
     kAsioEngineVersion        = 2;     // returns engine (host) asio implementation version,
                                        //   2 or higher
     kAsioResetRequest         = 3;     // request driver reset. if accepted, this
					//   will close the driver (ASIO_Exit() ) and
					//   re-open it again (ASIO_Init() etc). some
					//   drivers need to reconfigure for instance
                                        //   when the sample rate changes, or some basic
                                        //   changes have been made in ASIO_ControlPanel().
                                        //   returns 1L; note the request is merely passed
                                        //   to the application, there is no way to determine
                                        //   if it gets accepted at this time (but it usually
                                        //   will be).
     kAsioBufferSizeChange     = 4;     // not yet supported, will currently always return 0L.
                                        //   for now, use kAsioResetRequest instead.
                                        //   once implemented, the new buffer size is expected
                                        //   in <value>, and on success returns 1L
     kAsioResyncRequest        = 5;     // the driver went out of sync, such that
                                        //   the timestamp is no longer valid. this
                                        //   is a request to re-start the engine and
                                        //   slave devices (sequencer). returns 1 for ok,
                                        //   0 if not supported.
     kAsioLatenciesChanged     = 6;     // the drivers latencies have changed. The engine
                                        //   will refetch the latencies.
     kAsioSupportsTimeInfo     = 7;     // if host returns true here, it will expect the
                                        //   callback bufferSwitchTimeInfo to be called instead
                                        //   of bufferSwitch
     kAsioSupportsTimeCode     = 8;     // supports time code reading/writing
     kAsioSupportsInputMonitor = 9;     // supports input monitoring
     kAsioSupportsInputGain    = 10;    // unused and undefined
     kAsioSupportsInputMeter   = 11;    // unused and undefined
     kAsioSupportsOutputGain   = 12;    // unused and undefined
     kAsioSupportsOutputMeter  = 13;    // unused and undefined
     kAsioOverload             = 14;    // driver detected an overload

     kAsioNumMessageSelectors  = 15;




//---------------------------------------------------------------------------------------------------
//---------------------------------------------------------------------------------------------------

type
    TASIODriverInfo = packed record
      asioVersion   : longint;     // currently, 2
      driverVersion : longint;     // driver specific
      name          : array[0..31] of AnsiChar;
      errorMessage  : array[0..123] of AnsiChar;
      sysRef        : pointer;     // on input: system reference
                                   // (Windows: application main window handle, Mac & SGI: 0)
    end;

type
    PASIOClockSource = ^TASIOClockSource;
    TASIOClockSource = packed record
      index             : longint;    // as used for ASIOSetClockSource()
      associatedChannel : longint;    // for instance, S/PDIF or AES/EBU
      associatedGroup   : longint;    // see channel groups (ASIOGetChannelInfo())
      isCurrentSource   : TASIOBool;  // ASIOTrue if this is the current clock source
      name              : array[0..31] of AnsiChar;   // for user selection
    end;

type
    TASIOChannelInfo = packed record
      channel      : longint;                // on input, channel index
      isInput      : TASIOBool;              // on input
      isActive     : TASIOBool;              // on exit
      channelGroup : longint;                // dto
      vType        : TASIOSampleType;        // dto
      name         : array[0..31] of AnsiChar;   // dto
    end;

type
    PASIOBufferInfo = ^TASIOBufferInfo;
    TASIOBufferInfo = packed record
      isInput    : TASIOBool;               // on input:  ASIOTrue: input, else output
      channelNum : longint;                 // on input:  channel index
      buffers    : array[0..1] of pointer;  // on output: double buffer addresses
    end;

const
     kAsioEnableTimeCodeRead  = 1;    // no arguments
     kAsioDisableTimeCodeRead =	2;    // no arguments
     kAsioSetInputMonitor     =	3;    // ASIOInputMonitor* in params
     kAsioTransport           =	4;    // ASIOTransportParameters* in params
     kAsioSetInputGain        =	5;    // ASIOChannelControls* in params, apply gain
     kAsioGetInputMeter       =	6;    // ASIOChannelControls* in params, fill meter
     kAsioSetOutputGain       =	7;    // ASIOChannelControls* in params, apply gain
     kAsioGetOutputMeter      =	8;    // ASIOChannelControls* in params, fill meter
     kAsioCanInputMonitor     =	9;    // no arguments for kAsioCanXXX selectors
     kAsioCanTimeInfo         = 10;
     kAsioCanTimeCode         = 11;
     kAsioCanTransport        = 12;
     kAsioCanInputGain        = 13;
     kAsioCanInputMeter       = 14;
     kAsioCanOutputGain       = 15;
     kAsioCanOutputMeter      = 16;
	   //	DSD support
     //	The following extensions are required to allow switching
     //	and control of the DSD subsystem.
     kAsioSetIoFormat         = $23111961;		// PASIOIoFormat
     kAsioGetIoFormat         = $23111983;		// PASIOIoFormat
     kAsioCanDoIoFormat       = $23112004;		// PASIOIoFormat


type
    TASIOInputMonitor = packed record
      input     : longint;   // this input was set to monitor (or off), -1: all
      output    : longint;   // suggested output for monitoring the input (if so)
      gain      : longint;   // suggested gain, ranging 0 - 0x7fffffffL (-inf to +12 dB)
      state     : TASIOBool; // ASIOTrue => on, ASIOFalse => off
      pan       : longint;   // suggested pan, 0 => all left, 0x7fffffff => right
    end;

    TASIOChannelControls = packed record
      channel   : longint;        // on input, channel index
      isInput   : TASIOBool;      // on input
      gain      : longint;        // on input,  ranges 0 thru 0x7fffffff
      meter     : longint;        // on return, ranges 0 thru 0x7fffffff
      future    : array[0..31] of AnsiChar;
    end;

    TASIOTransportParameters = packed record
      command        : longint;                   // see enum below
      samplePosition : TASIOSamples;
      tracl          : longint;
      trackSwitches  : array[0..15] of longint;   // 512 tracks on/off
      future         : array[0..63] of AnsiChar;
    end;

const
     kTransStart       = 1;
     kTransStop        = 2;
     kTransLocate      = 3;    // to samplePosition
     kTransPunchIn     = 4;
     kTransPunchOut    = 5;
     kTransArmOn       = 6;    // track
     kTransArmOff      = 7;    // track
     kTransMonitorOn   = 8;    // track
     kTransMonitorOff  = 9;    // track
     kTransArm         = 10;   // trackSwitches
     kTransMonitor     = 11;   // trackSwitches



(*
// DSD support
//	Some notes on how to use ASIOIoFormatType.
//
//	The caller will fill the format with the request types.
//	If the board can do the request then it will leave the
//	values unchanged. If the board does not support the
//	request then it will change that entry to Invalid (-1)
//
//	So to request DSD then
//
//	ASIOIoFormat NeedThis={kASIODSDFormat};
//
//	if(ASE_SUCCESS != ASIOFuture(kAsioSetIoFormat,&NeedThis) ){
//		// If the board did not accept one of the parameters then the
//		// whole call will fail and the failing parameter will
//		// have had its value changes to -1.
//	}
//
// Note: Switching between the formats need to be done before the "prepared"
// state (see ASIO 2 documentation) is entered.
*)

type
    TASIOIoFormatType = longint;

const
     kASIOFormatInvalid = -1;
     kASIOPCMFormat     = 0;
     kASIODSDFormat     = 1;

type
    TASIOIoFormatType_e = longint;

type
    PASIOIoFormat = ^TASIOIoFormat;
    TASIOIoFormat = record
      FormatType : TASIOIoFormatType;
      future     : array[0..512-SizeOf(TASIOIoFormatType)-1] of byte;
    end;



type
    // don't use directly in 32bit Delphi (calling convention not supported), use TOpenASIO instead!
    IASIO = interface(IUnknown)
      function Init(sysHandle: HWnd): TASIOBool;
      procedure GetDriverName(name: PAnsiChar);
      function GetDriverVersion: longint;
      procedure GetErrorMessage(errorString: PAnsiChar);
      function Start: TASIOError;
      function Stop: TASIOError;
      function GetChannels(out numInputChannels, numOutputChannels: longint): TASIOError;
      function GetLatencies(out inputLatency, outputLatency: longint): TASIOError;
      function GetBufferSize(out minSize, maxSize, preferredSize, granularity: longint): TASIOError;
      function CanSampleRate(sampleRate: TASIOSampleRate): TASIOError;
      function GetSampleRate(out sampleRate: TASIOSampleRate): TASIOError;
      function SetSampleRate(sampleRate: TASIOSampleRate): TASIOError;
      function GetClockSources(clocks: PASIOClockSource; out numSources: longint): TASIOError;
      function SetClockSource(reference: longint): HResult;
      function GetSamplePosition(out sPos: TASIOSamples; out tStamp: TASIOTimeStamp): TASIOError;
      function GetChannelInfo(out info: TASIOChannelInfo): TASIOError;
      function CreateBuffers(bufferInfos: PASIOBufferInfo; numChannels, bufferSize: longint; const callbacks: TASIOCallbacks): TASIOError;
      function DisposeBuffers: TASIOError;
      function ControlPanel: TASIOError;
      function Future(selector: longint; opt: pointer): TASIOError;
      function OutputReady: TASIOError;
    end;

    TOpenASIO = class
    public
      Driver: IASIO;
      constructor Create(const AsioCLSID: TClsId);
      destructor Destroy; override;

      // IASIO functions
      function Init(sysHandle: HWnd): TASIOBool;
      procedure GetDriverName(name: PAnsiChar);
      function GetDriverVersion: longint;
      procedure GetErrorMessage(errorString: PAnsiChar);
      function Start: TASIOError;
      function Stop: TASIOError;
      function GetChannels(out numInputChannels, numOutputChannels: longint): TASIOError;
      function GetLatencies(out inputLatency, outputLatency: longint): TASIOError;
      function GetBufferSize(out minSize, maxSize, preferredSize, granularity: longint): TASIOError;
      function CanSampleRate(sampleRate: TASIOSampleRate): TASIOError;
      function GetSampleRate(out sampleRate: TASIOSampleRate): TASIOError;
      function SetSampleRate(sampleRate: TASIOSampleRate): TASIOError;
      function GetClockSources(clocks: PASIOClockSource; out numSources: longint): TASIOError;
      function SetClockSource(reference: longint): HResult;
      function GetSamplePosition(out sPos: TASIOSamples; out tStamp: TASIOTimeStamp): TASIOError;
      function GetChannelInfo(out info: TASIOChannelInfo): TASIOError;
      function CreateBuffers(bufferInfos: PASIOBufferInfo; numChannels, bufferSize: longint; const callbacks: TASIOCallbacks): TASIOError;
      function DisposeBuffers: TASIOError;
      function ControlPanel: TASIOError;
      function Future(selector: longint; option: pointer): TASIOError;
      function OutputReady: TASIOError;
    end;



implementation

{$IFDEF WIN32}
  {$IFNDEF CPUx64}
    {$DEFINE ThisCallHack}   // only necessary for 32bit in Windows (right?)
  {$ENDIF}
{$ENDIF}

function ASIOSamplesToInt64(const samples: TAsioSamples): Int64;
begin
  Result := (samples.hi * $100000000) + samples.lo;
end;

function Int64ToASIOSamples(const value: Int64): TASIOSamples;
begin
  Result.hi := (value and $FFFFFFFF00000000) shr 32;
  Result.lo := (value and $00000000FFFFFFFF);
end;

{ TOpenASIO }

constructor TOpenASIO.Create(const AsioCLSID: TClsId);
begin
  inherited Create;

  CoInitialize(nil);
  if not Succeeded(CoCreateInstance(AsioCLSID, nil, CLSCTX_INPROC_SERVER, AsioCLSID, Driver)) then
    Driver := nil;
end;

destructor TOpenASIO.Destroy;
begin
  if Assigned(Driver) then
    Driver := nil; // RELEASE
  CoUninitialize;

  inherited;
end;

{$IFDEF ThisCallHack}
function TOpenASIO.CanSampleRate(sampleRate: TASIOSampleRate): TASIOError;
asm
  push DWORD PTR [sampleRate+4]
  push DWORD PTR [sampleRate]
  mov  ecx, Self.Driver
  mov  eax, [ecx]
  call [eax+48]
end;

function TOpenASIO.ControlPanel: TASIOError;
asm
  mov ecx, Self.Driver
  mov eax, [ecx]
  call [eax+84]
end;

function TOpenASIO.CreateBuffers(bufferInfos: PASIOBufferInfo; numChannels, bufferSize: Integer; const callbacks: TASIOCallbacks): TASIOError;
asm
  push callbacks
  push bufferSize
  push numChannels
  push bufferInfos
  mov  ecx, Self.Driver
  mov  eax, [ecx]
  call [eax+76]
end;

function TOpenASIO.DisposeBuffers: TASIOError;
asm
  mov  ecx, Self.Driver
  mov  eax, [ecx]
  call [eax+80]
end;

function TOpenASIO.Future(selector: Integer; option: pointer): TASIOError;
asm
  push option
  push selector
  mov  ecx, Self.Driver
  mov  eax, [ecx]
  call [eax+88]
end;

function TOpenASIO.GetBufferSize(out minSize, maxSize, preferredSize, granularity: Integer): TASIOError;
asm
  push Granularity
  push PreferredSize
  push MaxSize
  push MinSize
  mov  ecx, Self.Driver
  mov  eax, [ecx]
  call [eax+44]
end;

function TOpenASIO.GetChannelInfo(out info: TASIOChannelInfo): TASIOError;
asm
  push info
  mov  ecx, Self.Driver
  mov  eax, [ecx]
  call [eax+72]
end;

function TOpenASIO.GetChannels(out numInputChannels, numOutputChannels: Integer): TASIOError;
asm
  push numOutputChannels
  push numInputChannels
  mov  ecx, Self.Driver
  mov  eax, [ecx]
  call [eax+36]
end;

function TOpenASIO.GetClockSources(clocks: PASIOClockSource; out numSources: Integer): TASIOError;
asm
  push NumSources
  push Clocks
  mov  ecx, Self.Driver
  mov  eax, [ecx]
  call [eax+60]
end;

procedure TOpenASIO.GetDriverName(name: PAnsiChar);
asm
  push name
  mov  ecx, Self.Driver
  mov  eax, [ecx]
  call [eax+16]
end;

function TOpenASIO.GetDriverVersion: longint;
asm
  mov  ecx, Self.Driver
  mov  eax, [ecx]
  call [eax+20]
end;

procedure TOpenASIO.GetErrorMessage(errorString: PAnsiChar);
asm
  push Error
  mov  ecx, Self.Driver
  mov  eax, [ecx]
  call [eax+24]
end;

function TOpenASIO.GetLatencies(out inputLatency, outputLatency: Integer): TASIOError;
asm
  push outputLatency
  push inputLatency
  mov  ecx, Self.Driver
  mov  eax, [ecx]
  call [eax+40]
end;

function TOpenASIO.GetSamplePosition(out sPos: TASIOSamples; out tStamp: TASIOTimeStamp): TASIOError;
asm
  push tStamp
  push sPos
  mov  ecx, Self.Driver
  mov  eax, [ecx]
  call [eax+68]
end;

function TOpenASIO.GetSampleRate(out sampleRate: TASIOSampleRate): TASIOError;
asm
  push sampleRate
  mov  ecx, Self.Driver
  mov  eax, [ecx]
  call [eax+52]
end;

function TOpenASIO.Init(sysHandle: HWnd): TASIOBool;
asm
  push sysHandle
  mov  ecx, Self.Driver
  mov  eax, [ecx]
  call [eax+12]
end;

function TOpenASIO.OutputReady: TASIOError;
asm
  mov ecx, Self.Driver
  mov eax, [ecx]
  call [eax+92]
end;

function TOpenASIO.SetClockSource(reference: Integer): HResult;
asm
  push reference
  mov  ecx, Self.Driver
  mov  eax, [ecx]
  call [eax+64]
end;

function TOpenASIO.SetSampleRate(sampleRate: TASIOSampleRate): TASIOError;
asm
  push DWORD PTR [sampleRate+4]
  push DWORD PTR [sampleRate]
  mov  ecx, Self.Driver
  mov  eax, [ecx]
  call [eax+56]
end;

function TOpenASIO.Start: TASIOError;
asm
  mov  ecx, Self.Driver
  mov  eax, [ecx]
  call [eax+28]
end;

function TOpenASIO.Stop: TASIOError;
asm
  mov  ecx, Self.Driver
  mov  eax, [ecx]
  call [eax+32]
end;
{$ENDIF}

{$IFNDEF ThisCallHack}
function TOpenASIO.CanSampleRate(sampleRate: TASIOSampleRate): TASIOError;
begin
  Result := Driver.CanSampleRate(sampleRate);
end;

function TOpenASIO.ControlPanel: TASIOError;
begin
  Result := Driver.ControlPanel;
end;

function TOpenASIO.CreateBuffers(bufferInfos: PASIOBufferInfo; numChannels, bufferSize: Integer; const callbacks: TASIOCallbacks): TASIOError;
begin
  Result := Driver.CreateBuffers(bufferInfos, numChannels, bufferSize, callbacks);
end;

function TOpenASIO.DisposeBuffers: TASIOError;
begin
  Result := Driver.DisposeBuffers;
end;

function TOpenASIO.Future(selector: Integer; option: pointer): TASIOError;
begin
  Result := Driver.Future(selector, option);
end;

function TOpenASIO.GetBufferSize(out minSize, maxSize, preferredSize, granularity: Integer): TASIOError;
begin
  Result := Driver.GetBufferSize(minSize, maxSize, preferredSize, granularity);
end;

function TOpenASIO.GetChannelInfo(out info: TASIOChannelInfo): TASIOError;
begin
  Result := Driver.GetChannelInfo(info);
end;

function TOpenASIO.GetChannels(out numInputChannels, numOutputChannels: Integer): TASIOError;
begin
  Result := Driver.GetChannels(numInputChannels, numOutputChannels);
end;

function TOpenASIO.GetClockSources(clocks: PASIOClockSource; out numSources: Integer): TASIOError;
begin
  Result := Driver.GetClockSources(clocks, numSources);
end;

procedure TOpenASIO.GetDriverName(name: PAnsiChar);
begin
  Driver.GetDriverName(name);
end;

function TOpenASIO.GetDriverVersion: longint;
begin
  Result := Driver.GetDriverVersion;
end;

procedure TOpenASIO.GetErrorMessage(errorString: PAnsiChar);
begin
  Driver.GetErrorMessage(errorString);
end;

function TOpenASIO.GetLatencies(out inputLatency, outputLatency: Integer): TASIOError;
begin
  Result := Driver.GetLatencies(inputLatency, outputLatency);
end;

function TOpenASIO.GetSamplePosition(out sPos: TASIOSamples; out tStamp: TASIOTimeStamp): TASIOError;
begin
  Result := Driver.GetSamplePosition(sPos, tStamp);
end;

function TOpenASIO.GetSampleRate(out sampleRate: TASIOSampleRate): TASIOError;
begin
  Result := Driver.GetSampleRate(sampleRate);
end;

function TOpenASIO.Init(sysHandle: HWnd): TASIOBool;
begin
  Result := Driver.Init(sysHandle);
end;

function TOpenASIO.OutputReady: TASIOError;
begin
  Result := Driver.OutputReady;
end;

function TOpenASIO.SetClockSource(reference: Integer): HResult;
begin
  Result := Driver.SetClockSource(reference);
end;

function TOpenASIO.SetSampleRate(sampleRate: TASIOSampleRate): TASIOError;
begin
  Result := Driver.SetSampleRate(sampleRate);
end;

function TOpenASIO.Start: TASIOError;
begin
  Result := Driver.Start
end;

function TOpenASIO.Stop: TASIOError;
begin
  Result := Driver.Stop;
end;
{$ENDIF}

end.
