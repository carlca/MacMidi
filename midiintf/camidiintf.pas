unit caMidiIntf;

interface

uses
  Classes, SysUtils, caMidiTypes;

type
  IcaMidiInterface = interface
    function CreateMidiClient(Errors: TStrings): longword;
    function CreateMidiInputPort(MidiClient: longword; Errors: TStrings): longword;
    function CreateMidiOutputPort(MidiClient: longword; Errors: TStrings): longword;
    procedure GetDevices(InOut: TcaMidiInOut; Devices: TStrings);
    procedure SendCC(DeviceIndex, OutputPort: longword; Channel, CC: Byte; Errors: TStrings);
    procedure SendPGM(DeviceIndex, OutputPort: longword; Channel, PGM: Byte; Errors: TStrings);
  end;

var
  Midi: IcaMidiInterface;

implementation

end.


